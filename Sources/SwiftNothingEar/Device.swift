@preconcurrency import CoreBluetooth
import Combine
import Foundation
import os.log

#if os(macOS)
import IOBluetooth
#endif

public enum ConnectionStatus: Sendable {
    case disconnected
    case scanning
    case connecting
    case connected
    case foundConnected
}

public enum ConnectionError: Error, LocalizedError, Sendable {

    public enum Bluetooth: Sendable {
        case poweredOff
        case unauthorized
        case unavailable
    }

    case bluetooth(Bluetooth)
    case connectionFailed
    case deviceNotFound
    case invalidResponse
    case timeout
    case unsupportedOperation
}

public struct Callback {

    let onDiscover: (CBPeripheral) -> Void

    let onConnect: (Result<DeviceInfo, Error>) -> Void
    let onDisconnect: (Result<Void, Error>) -> Void

    let onUpdateBattery: (Battery?) -> Void
    let onUpdateNoiseCancellation: (NoiseCancellationMode?) -> Void
    let onUpdateSpatialAudio: (SpatialAudioMode?) -> Void
    let onUpdateEnhancedBass: (EnhancedBass?) -> Void
    let onUpdateEQPreset: (EQPreset?) -> Void
    let onUpdateEQPresetCustom: (EQPresetCustom?) -> Void
    let onUpdateDeviceSettings: (DeviceSettings) -> Void
    let onUpdateRingBuds: (RingBuds) -> Void

    let onError: (ConnectionError) -> Void

    public init(
        onDiscover: @escaping (CBPeripheral) -> Void,
        onConnect: @escaping (Result<DeviceInfo, Error>) -> Void,
        onDisconnect: @escaping (Result<Void, Error>) -> Void,
        onUpdateBattery: @escaping (Battery?) -> Void,
        onUpdateANCMode: @escaping (NoiseCancellationMode?) -> Void,
        onUpdateSpatialAudio: @escaping (SpatialAudioMode?) -> Void,
        onUpdateEnhancedBass: @escaping (EnhancedBass?) -> Void,
        onUpdateEQPreset: @escaping (EQPreset?) -> Void,
        onUpdateEQPresetCustom: @escaping (EQPresetCustom?) -> Void = { _ in },
        onUpdateDeviceSettings: @escaping (DeviceSettings) -> Void,
        onUpdateRingBuds: @escaping (RingBuds) -> Void,
        onError: @escaping (ConnectionError) -> Void
    ) {
        self.onDiscover = onDiscover
        self.onConnect = onConnect
        self.onDisconnect = onDisconnect
        self.onUpdateBattery = onUpdateBattery
        self.onUpdateNoiseCancellation = onUpdateANCMode
        self.onUpdateSpatialAudio = onUpdateSpatialAudio
        self.onUpdateEnhancedBass = onUpdateEnhancedBass
        self.onUpdateEQPreset = onUpdateEQPreset
        self.onUpdateEQPresetCustom = onUpdateEQPresetCustom
        self.onUpdateDeviceSettings = onUpdateDeviceSettings
        self.onUpdateRingBuds = onUpdateRingBuds
        self.onError = onError
    }
}

@MainActor
public final class Device: NSObject {

    public private(set) var connectionStatus: ConnectionStatus = .disconnected

    public private(set) var deviceInfo: DeviceInfo?
    public private(set) var deviceSettings: DeviceSettings?

    public private(set) var battery: Battery?
    public private(set) var ancMode: NoiseCancellationMode?
    public private(set) var enhancedBass: EnhancedBass?
    public private(set) var eqPreset: EQPreset?
    public private(set) var eqPresetCustom: EQPresetCustom?
    public private(set) var spatialAudio: SpatialAudioMode?
    public private(set) var ringBuds: RingBuds?

    private let callback: Callback

    // Fast Pair service UUID for discovering Nothing devices
    private let fastPairUUID = CBUUID(string: "FE2C")

    // Standard BLE services to filter out when looking for proprietary service
    private let standardServices: Set<String> = [
        "1800", // Generic Access
        "1801", // Generic Attribute
        "180A", // Device Information
        "180F", // Battery Service
        "1844", // LE Audio - Volume Control
        "1846", // LE Audio - Audio Stream Control
        "184D", // LE Audio - Published Audio Capabilities
        "184E", // LE Audio - Common Audio Service
        "184F", // LE Audio - Hearing Access Service
        "1850", // LE Audio - Telephony and Media Audio
        "1853", // LE Audio - Microphone Control
        "1855", // LE Audio - Coordinated Set Identification
        "FE2C"  // Fast Pair (used for discovery, not for communication)
    ]

    // Known proprietary services from Nothing/CMF devices, prioritised when scoring
    private let preferredProprietaryServices: [String: Int] = [
        "0000FD90-0000-1000-8000-00805F9B34FB": 300 // Nothing Ear / CMF control service
    ]

    private nonisolated(unsafe) var centralManager: CBCentralManager!
    private nonisolated(unsafe) var connectedPeripheral: CBPeripheral?

    // Dynamically discovered characteristics
    private nonisolated(unsafe) var proprietaryService: CBService?
    private nonisolated(unsafe) var writeCharacteristic: CBCharacteristic?
    private nonisolated(unsafe) var notifyCharacteristic: CBCharacteristic?

    // Service discovery state
    private var candidateServices: [CBService] = []
    private var servicesToCheck = 0
    private var servicesChecked = 0

    private var operationID: UInt8 = 1
    private var pendingOperations: [UInt8: (Data) -> Void] = [:]

    // Track initial device info loading state
    private var hasReceivedSerialNumber = false
    private var hasReceivedFirmware = false
    private var isInitialConnectionComplete = false
    private var connectionTimeoutTask: Task<Void, Never>?

    public init(_ callback: Callback) {
        self.callback = callback
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
}

// MARK: Public Interface

extension Device {

    public var isConnected: Bool {
        connectionStatus == .connected && connectedPeripheral?.state == .connected
    }

    public func startScanning() {
        if let error = error(from: centralManager.state) {
            callback.onError(error)
            return
        }

        // First check if we already have a connected Nothing Ear device
        guard !checkAndConnectToExistingDevices() else {
            return
        }

        connectionStatus = .scanning
        centralManager.scanForPeripherals(withServices: [fastPairUUID])
    }

    public func stopScanning() {
        centralManager.stopScan()

        if connectionStatus == .scanning {
            connectionStatus = .disconnected
        }
    }

    @discardableResult
    public func checkAndConnectToExistingDevices() -> Bool {
        // Check for already connected peripherals with Fast Pair service
        let connectedPeripherals = centralManager.retrieveConnectedPeripherals(withServices: [fastPairUUID])

        guard let peripheral = connectedPeripherals.first else {
            return false
        }

        connectionStatus = .foundConnected
        connect(to: peripheral)

        return true
    }

    public func connect(to peripheral: CBPeripheral) {
        stopScanning()
        connectionStatus = .connecting
        connectedPeripheral = peripheral
        centralManager.connect(peripheral, options: nil)
    }

    public func disconnect() {
        guard let connectedPeripheral else {
            return
        }

        centralManager.cancelPeripheralConnection(connectedPeripheral)
    }

    public func setNoiseCancellationMode(_ mode: NoiseCancellationMode) {
        guard isConnected else {
            callback.onError(.connectionFailed)
            return
        }

        guard
            let deviceInfo,
            deviceInfo.model.supportsNoiseCancellation
        else {
            callback.onError(.unsupportedOperation)
            return
        }

        sendRequest(
            .setANCMode(
                mode,
                operationID: nextOperationID()
            )
        )
    }

    public func setEnhancedBass(_ settings: EnhancedBass) {
        guard isConnected else {
            callback.onError(.connectionFailed)
            return
        }

        guard
            let deviceInfo,
            deviceInfo.model.supportsEnhancedBass
        else {
            callback.onError(.unsupportedOperation)
            return
        }

        sendRequest(
            .setEnhancedBass(
                settings,
                operationID: nextOperationID()
            )
        )
    }

    public func setEQPreset(_ preset: EQPreset) {
        guard isConnected else {
            callback.onError(.connectionFailed)
            return
        }

        sendRequest(
            .setEQPreset(
                preset,
                operationID: nextOperationID()
            )
        )
    }

    public func setInEarDetection(_ isEnabled: Bool) {
        guard isConnected else {
            callback.onError(.connectionFailed)
            return
        }

        sendRequest(
            .setInEarDetection(
                isEnabled,
                operationID: nextOperationID()
            )
        )
    }

    public func setLowLatency(_ isEnabled: Bool) {
        guard isConnected else {
            callback.onError(.connectionFailed)
            return
        }

        sendRequest(
            .setLowLatency(
                isEnabled,
                operationID: nextOperationID()
            )
        )
    }

    public func setSpatialAudioMode(_ mode: SpatialAudioMode) {
        guard isConnected else {
            callback.onError(.connectionFailed)
            return
        }

        guard
            let deviceInfo,
            deviceInfo.model.supportsSpatialAudio
        else {
            callback.onError(.unsupportedOperation)
            return
        }

        sendRequest(
            .setSpatialAudioMode(
                mode,
                operationID: nextOperationID()
            )
        )
    }

    public func setGesture(
        type: GestureType,
        action: GestureAction,
        device: GestureDevice? = nil
    ) {
        guard isConnected else {
            callback.onError(.connectionFailed)
            return
        }

        sendRequest(
            .setGesture(
                .init(
                    type: type,
                    action: action,
                    device: device
                ),
                operationID: nextOperationID()
            )
        )
    }

    public func setRingBuds(_ ringBuds: RingBuds) {
        guard isConnected else {
            callback.onError(.connectionFailed)
            return
        }

        guard
            let deviceInfo,
            deviceInfo.model.supportsRingBuds
        else {
            callback.onError(.unsupportedOperation)
            return
        }

        sendRequest(
            .setRingBuds(
                ringBuds,
                operationID: nextOperationID()
            )
        )
    }
}

// MARK: Private Methods

extension Device {

    private func refreshDeviceStatus() {
        guard isConnected else { return }

        // Reset state flags for new connection
        hasReceivedSerialNumber = false
        hasReceivedFirmware = false
        isInitialConnectionComplete = false

        // Cancel any existing timeout task
        connectionTimeoutTask?.cancel()

        Logger.bluetooth.info("📋 Starting initial device info request")

        // Start timeout task (10 seconds)
        connectionTimeoutTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 10_000_000_000) // 10s

            guard !Task.isCancelled else { return }

            if !isInitialConnectionComplete {
                Logger.bluetooth.warning("⏱️ Connection timeout - device did not respond in time")
                callback.onError(.timeout)

                // Disconnect from device
                if let peripheral = connectedPeripheral {
                    centralManager.cancelPeripheralConnection(peripheral)
                }
            }
        }

        // First, request critical device info (serial number and firmware)
        // We'll request other info only after receiving these
        sendReadSerialNumberRequest()

        // Send firmware request with a slight delay to avoid overwhelming the device
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            await MainActor.run {
                sendReadFirmwareRequest()
            }
        }
    }

    private func completeInitialConnection() {
        guard !isInitialConnectionComplete else { return }
        guard hasReceivedSerialNumber && hasReceivedFirmware else { return }

        isInitialConnectionComplete = true

        // Cancel timeout task since we successfully received initial info
        connectionTimeoutTask?.cancel()
        connectionTimeoutTask = nil

        Logger.bluetooth.info("✅ Initial device info received, notifying connection success")

        // Notify that connection is complete
        if let deviceInfo {
            callback.onConnect(.success(deviceInfo))
        }

        // Now request all other device information
        Logger.bluetooth.info("📋 Requesting additional device information")

        let tasks: [() -> Void] = [
            // Request device settings
            sendReadInEarRequest,
            sendReadLowLatencyRequest,

            // Request other info
            sendEnhancedBassRequest,
            sendReadANCRequest,
            sendReadEQRequest,
            sendReadBatteryRequest,
            sendReadGestureRequest,
            sendReadSpatialAudioRequest,
            sendReadRingBudsRequest
        ]

        runTasks(tasks, delay: 0.1)
    }

    private func runTasks(_ tasks: [() -> Void], delay: TimeInterval) {
        for (index, task) in tasks.enumerated() {
            Task {
                let nanoseconds = index * Int(delay * 1_000_000_000)
                try? await Task.sleep(nanoseconds: UInt64(nanoseconds))
                task()
            }
        }
    }

    private func nextOperationID() -> UInt8 {
        operationID = operationID >= 250 ? 1 : operationID + 1
        return operationID
    }

    private func sendReadBatteryRequest() {
        Logger.bluetooth.debug("🔋 Sending read battery request")

        let request = BluetoothRequest(
            command: BluetoothCommand.RequestRead.battery,
            payload: [],
            operationID: nextOperationID()
        )
        sendRequest(request)
    }

    private func sendReadANCRequest() {
        guard
            let deviceInfo = deviceInfo,
            deviceInfo.model.supportsNoiseCancellation
        else {
            return
        }

        Logger.bluetooth.debug("🔇 Sending read ANC request")

        let request = BluetoothRequest(
            command: BluetoothCommand.RequestRead.anc,
            payload: [],
            operationID: nextOperationID()
        )
        sendRequest(request)
    }

    private func sendReadEQRequest() {
        Logger.bluetooth.debug("🎵 Sending read EQ request")

        let isListeningModeSupported = deviceInfo?.model.isListeningModeSupported ?? false
        let command = isListeningModeSupported
            ? BluetoothCommand.RequestRead.listeningMode
            : BluetoothCommand.RequestRead.eq
        let request = BluetoothRequest(
            command: command,
            payload: [],
            operationID: nextOperationID()
        )
        sendRequest(request)
    }

    private func sendReadFirmwareRequest() {
        Logger.bluetooth.debug("💾 Sending read firmware request")

        let request = BluetoothRequest(
            command: BluetoothCommand.RequestRead.firmware,
            payload: [],
            operationID: nextOperationID()
        )
        sendRequest(request)
    }

    private func sendReadInEarRequest() {
        Logger.bluetooth.debug("👂 Sending in-ear detection request")

        let request = BluetoothRequest(
            command: BluetoothCommand.RequestRead.inEarDetection,
            payload: [],
            operationID: nextOperationID()
        )
        sendRequest(request)
    }

    private func sendReadLowLatencyRequest() {
        Logger.bluetooth.debug("⚡ Sending read latency request")

        let request = BluetoothRequest(
            command: BluetoothCommand.RequestRead.lowLatency,
            payload: [],
            operationID: nextOperationID()
        )
        sendRequest(request)
    }

    private func sendEnhancedBassRequest() {
        Logger.bluetooth.debug("🎶 Sending read enhanced bass request")

        let request = BluetoothRequest(
            command: BluetoothCommand.RequestRead.enhancedBass,
            payload: [],
            operationID: nextOperationID()
        )
        sendRequest(request)
    }

    private func sendReadGestureRequest() {
        Logger.bluetooth.debug("👆 Sending read gesture request")

        let request = BluetoothRequest(
            command: BluetoothCommand.RequestRead.gesture,
            payload: [],
            operationID: nextOperationID()
        )
        sendRequest(request)
    }

    private func sendReadSerialNumberRequest() {
        Logger.bluetooth.debug("🏷️ Sending read serial number request")

        let request = BluetoothRequest(
            command: BluetoothCommand.RequestRead.serialNumber,
            payload: [],
            operationID: nextOperationID()
        )
        sendRequest(request)
    }

    private func sendReadSpatialAudioRequest() {
        guard
            let deviceInfo = deviceInfo,
            deviceInfo.model.supportsSpatialAudio
        else {
            return
        }

        Logger.bluetooth.debug("🎧 Sending read spatial audio request")

        let request = BluetoothRequest(
            command: BluetoothCommand.RequestRead.spatialAudio,
            payload: [],
            operationID: nextOperationID()
        )
        sendRequest(request)
    }

    private func sendReadRingBudsRequest() {
        guard
            let deviceInfo,
            deviceInfo.model.supportsRingBuds
        else {
            return
        }

        Logger.bluetooth.debug("🔔 Sending read ring buds request")
        let request = BluetoothRequest(
            command: BluetoothCommand.RequestRead.ringBuds,
            payload: [],
            operationID: nextOperationID()
        )
        sendRequest(request)
    }

    private func sendRequest(_ request: BluetoothRequest) {
        guard
            let connectedPeripheral,
            let writeCharacteristic
        else {
            callback.onError(.connectionFailed)
            return
        }

        let data = Data(request.toBytes())
        Logger.logBluetoothData(Array(data), direction: .outgoing)
        connectedPeripheral.writeValue(data, for: writeCharacteristic, type: .withResponse)
    }

    private func processResponse(_ data: Data) {
        Logger.logBluetoothData(Array(data), direction: .incoming)

        guard let response = BluetoothResponse(data: Array(data)) else {
            callback.onError(.invalidResponse)
            return
        }

        switch response.command {
            case BluetoothCommand.Response.serialNumber:
                let deviceName = connectedPeripheral?.name ?? "Unknown"
                if let serialNumber = response.parseSerialNumber(),
                   let detectedModel = DeviceModel.getModel(for: deviceName, serialNumber: serialNumber) {
                    updateDeviceInfo { deviceInfo in
                        deviceInfo.model = detectedModel
                        deviceInfo.serialNumber = serialNumber
                    }
                    hasReceivedSerialNumber = true
                    Logger.parsing.info("🏷️ Parsed device info: model=\(detectedModel.code, privacy: .public), serial=\(serialNumber, privacy: .public)")

                    // Check if we can complete the initial connection
                    completeInitialConnection()
                } else {
                    Logger.parsing.warning("🏷️ Failed to parse serial number from response")
                }

            case BluetoothCommand.Response.firmware:
                let firmwareVersion = response.parseFirmwareVersion()
                if !firmwareVersion.isEmpty {
                    updateDeviceInfo { deviceInfo in
                        deviceInfo.firmwareVersion = firmwareVersion
                    }
                    hasReceivedFirmware = true
                    Logger.parsing.info("💾 Parsed firmware version: \(firmwareVersion, privacy: .public)")

                    // Check if we can complete the initial connection
                    completeInitialConnection()
                } else {
                    Logger.parsing.warning("💾 Failed to parse firmware version")
                }

            case BluetoothCommand.Response.batteryA,
                BluetoothCommand.Response.batteryB:
                if let deviceInfo, let battery = response.parseBattery(model: deviceInfo.model) {
                    self.battery = battery
                    callback.onUpdateBattery(battery)

                    let batteryDescription: String
                    switch battery {
                    case .single(let level):
                        batteryDescription = "level=\(level.level)%, charging=\(level.isCharging)"
                    case .budsWithCase(let caseLevel, let leftBud, let rightBud):
                        batteryDescription = "case=\(caseLevel.level)%, left=\(leftBud.level)%, right=\(rightBud.level)%"
                    }
                    Logger.parsing.info("🔋 Parsed battery: \(batteryDescription, privacy: .public)")
                } else {
                    Logger.parsing.warning("🔋 Failed to parse battery data")
                }

            case BluetoothCommand.Response.ancA,
                BluetoothCommand.Response.ancB:
                if let ancMode = response.parseANCMode() {
                    self.ancMode = ancMode
                    callback.onUpdateNoiseCancellation(ancMode)
                    Logger.parsing.info("🔇 Parsed ANC mode: \(String(describing: ancMode), privacy: .public)")
                } else {
                    Logger.parsing.warning("🔇 Failed to parse ANC mode")
                }

            case BluetoothCommand.Response.spatialAudio:
                if let spatialAudioMode = response.parseSpatialAudioMode(model: deviceInfo?.model) {
                    self.spatialAudio = spatialAudioMode
                    callback.onUpdateSpatialAudio(spatialAudioMode)
                    Logger.parsing.info("🎧 Parsed spatial audio mode: \(spatialAudioMode.displayName, privacy: .public)")
                } else {
                    Logger.parsing.warning("🎧 Failed to parse spatial audio mode")
                }

            case BluetoothCommand.Response.eqA,
                BluetoothCommand.Response.eqB:
                if let eqPreset = response.parseEQPreset() {
                    self.eqPreset = eqPreset
                    callback.onUpdateEQPreset(eqPreset)
                    Logger.parsing.info("🎵 Parsed EQ preset: \(String(describing: eqPreset), privacy: .public)")
                } else {
                    Logger.parsing.warning("🎵 Failed to parse EQ preset")
                }

            case BluetoothCommand.Response.customEQ:
                if let customEQ = response.parseCustomEQPreset() {
                    self.eqPresetCustom = customEQ
                    callback.onUpdateEQPresetCustom(customEQ)
                    Logger.parsing.info("🎛️ Parsed custom EQ: bass=\(customEQ.bass, privacy: .public), mid=\(customEQ.mid, privacy: .public), treble=\(customEQ.treble, privacy: .public)")
                } else {
                    Logger.parsing.warning("🎛️ Failed to parse custom EQ")
                }

            case BluetoothCommand.Response.inEarDetection:
                if let inEarDetection = response.parseInEarDetection() {
                    updateDeviceSettings { settings in
                        settings.inEarDetection = inEarDetection
                    }
                    Logger.parsing.info("👂 Parsed in-ear detection: \(inEarDetection ? "enabled" : "disabled", privacy: .public)")
                } else {
                    Logger.parsing.warning("👂 Failed to parse in-ear detection or unsupported by device")
                }

            case BluetoothCommand.Response.lowLatency:
                if let lowLatency = response.parseLowLatency() {
                    updateDeviceSettings { settings in
                        settings.lowLatency = lowLatency
                    }
                    Logger.parsing.info("⚡ Parsed low latency: \(lowLatency ? "enabled" : "disabled", privacy: .public)")
                } else {
                    Logger.parsing.warning("⚡ Failed to parse low latency setting")
                }

            case BluetoothCommand.Response.enhancedBass:
                if let enhancedBass = response.parseEnhancedBassSettings() {
                    self.enhancedBass = enhancedBass
                    callback.onUpdateEnhancedBass(enhancedBass)
                    Logger.parsing.info("🎶 Parsed enhanced bass: \(enhancedBass.isEnabled ? "enabled" : "disabled", privacy: .public)")
                } else {
                    Logger.parsing.warning("🎶 Failed to parse enhanced bass settings")
                }

            case BluetoothCommand.Response.gesture:
                let gestures = response.parseGestures()
                if !gestures.isEmpty {
                    Logger.parsing.info("👆 Parsed gestures: \(gestures.count, privacy: .public) gesture(s)")
                } else {
                    Logger.parsing.warning("👆 No gestures parsed from response")
                }

            case BluetoothCommand.Response.ringBuds:
                if let ringBuds = response.parseRingBuds() {
                    self.ringBuds = ringBuds
                    callback.onUpdateRingBuds(ringBuds)
                    Logger.parsing.info("🔔 Parsed ring buds: \(ringBuds.isOn ? "ringing" : "not ringing", privacy: .public)")
                } else {
                    Logger.parsing.info("🔔 ⚡ Failed to parse ring bugs")
                }

            default:
                Logger.parsing.warning("❓ Unknown response: command = \(response.command, privacy: .public), payload = \(response.payload.map { String(format: "%02X", $0) } .joined(separator: " "), privacy: .public)")
        }
    }

    private func updateDeviceInfo(_ update: (inout DeviceInfo) -> Void) {
        if deviceInfo == nil {
            self.deviceInfo = .empty
        }

        update(&deviceInfo!)
    }

    private func updateDeviceSettings(_ update: (inout DeviceSettings) -> Void) {
        if deviceSettings == nil {
            self.deviceSettings = .default
        }

        update(&deviceSettings!)

        if let deviceSettings {
            callback.onUpdateDeviceSettings(deviceSettings)
        }
    }

    private func error(from state: CBManagerState) -> ConnectionError? {
        switch state {
            case .poweredOn:
                nil
            case .poweredOff:
                .bluetooth(.poweredOff)
            case .unauthorized:
                .bluetooth(.unauthorized)
            case .unsupported, .resetting, .unknown:
                .bluetooth(.unavailable)
            @unknown default:
                nil
        }
    }
}

// MARK: CBCentralManagerDelegate

extension Device: CBCentralManagerDelegate {

    nonisolated public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            if central.state == .poweredOn {
                checkAndConnectToExistingDevices()
            } else if let error = error(from: central.state) {
                connectionStatus = .disconnected
                callback.onError(error)
            }
        }
    }

    nonisolated public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        Task { @MainActor in
            Logger.bluetooth.debug("🔍 Discovered peripheral: \(peripheral.name ?? "unknown", privacy: .public) (RSSI: \(RSSI.intValue))")
            callback.onDiscover(peripheral)
        }
    }

    nonisolated public func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        Task { @MainActor in
            connectionStatus = .connected

            Logger.bluetooth.info("✅ Connected to peripheral: \(peripheral.name ?? "unknown", privacy: .public)")

            peripheral.delegate = self
            peripheral.discoverServices(nil)

            #if os(macOS)
            // Get bluetooth address from IOBluetooth
            if let paired = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] {
                for bluetoothDevice in paired where bluetoothDevice.name == peripheral.name {
                    if let address = bluetoothDevice.addressString {
                        let bluetoothAddress = address
                            .replacingOccurrences(of: "-", with: ":")
                            .uppercased()
                        updateDeviceInfo { deviceInfo in
                            deviceInfo.bluetoothAddress = bluetoothAddress
                        }
                    }
                }
            }
            #endif
        }
    }

    nonisolated public func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        connectedPeripheral = nil
        proprietaryService = nil
        writeCharacteristic = nil
        notifyCharacteristic = nil

        Task { @MainActor in
            connectionStatus = .disconnected

            // Cancel timeout task if running
            connectionTimeoutTask?.cancel()
            connectionTimeoutTask = nil

            // Reset connection state
            hasReceivedSerialNumber = false
            hasReceivedFirmware = false
            isInitialConnectionComplete = false

            // Reset service discovery state
            candidateServices.removeAll()
            servicesToCheck = 0
            servicesChecked = 0

            Logger.bluetooth.error("❌ Failed to connect to peripheral: \(peripheral.name ?? "unknown", privacy: .public)")

            if let error {
                callback.onConnect(.failure(error))
            }
        }
    }

    nonisolated public func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        connectedPeripheral = nil
        proprietaryService = nil
        writeCharacteristic = nil
        notifyCharacteristic = nil

        Task { @MainActor in
            connectionStatus = .disconnected

            // Cancel timeout task if running
            connectionTimeoutTask?.cancel()
            connectionTimeoutTask = nil

            // Reset connection state
            hasReceivedSerialNumber = false
            hasReceivedFirmware = false
            isInitialConnectionComplete = false

            // Reset service discovery state
            candidateServices.removeAll()
            servicesToCheck = 0
            servicesChecked = 0

            Logger.bluetooth.info("❌ Disconnected from peripheral: \(peripheral.name ?? "unknown", privacy: .public)")

            if let error {
                callback.onDisconnect(.failure(error))
            } else {
                callback.onDisconnect(.success(()))
            }
        }
    }
}

// MARK: CBPeripheralDelegate

extension Device: CBPeripheralDelegate {

    nonisolated public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?
    ) {
        guard error == nil else {
            Task { @MainActor in
                callback.onError(.connectionFailed)
            }
            return
        }

        guard let services = peripheral.services else {
            Task { @MainActor in
                callback.onError(.connectionFailed)
            }
            return
        }

        // Create a local copy to avoid data races
        let servicesCount = services.count
        let serviceUUIDs = services.map { $0.uuid.uuidString.uppercased() }

        // Log discovered services for debugging
        Task { @MainActor in
            Logger.bluetooth.debug("🔍 Discovered \(servicesCount) service(s)")
            for uuid in serviceUUIDs {
                Logger.bluetooth.debug("  📦 Service: \(uuid, privacy: .public)")
            }
        }

        // Filter out standard BLE services to find proprietary Nothing service
        Task { @MainActor in
            let proprietaryCandidates = services.filter { service in
                let serviceUUID = service.uuid.uuidString.uppercased()
                return !standardServices.contains(serviceUUID)
            }

            candidateServices = proprietaryCandidates
            servicesToCheck = proprietaryCandidates.count
            servicesChecked = 0

            Logger.bluetooth.info("🎯 Found \(proprietaryCandidates.count) proprietary service candidate(s) after filtering")

            if proprietaryCandidates.isEmpty {
                Logger.bluetooth.error("❌ No proprietary services found")
                callback.onError(.connectionFailed)
                return
            }

            // Discover characteristics for each candidate service
            for service in proprietaryCandidates {
                Logger.bluetooth.debug("🔍 Checking service: \(service.uuid.uuidString, privacy: .public)")
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }

    nonisolated public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        guard error == nil else {
            Task { @MainActor in
                callback.onError(.connectionFailed)
            }
            return
        }

        guard let characteristics = service.characteristics, !characteristics.isEmpty else {
            Task { @MainActor in
                await handleServiceChecked()
            }
            return
        }

        // Create local copies to avoid data races
        let characteristicsCount = characteristics.count
        let serviceUUID = service.uuid.uuidString
        let charInfos = characteristics.map {
            (uuid: $0.uuid.uuidString, properties: $0.properties)
        }

        Task { @MainActor in
            Logger.bluetooth.debug("🔍 Discovered \(characteristicsCount) characteristic(s) for service \(serviceUUID, privacy: .public)")

            for charInfo in charInfos {
                let propsDesc = describeProperties(charInfo.properties)
                Logger.bluetooth.debug("  🔧 Characteristic: \(charInfo.uuid, privacy: .public) - \(propsDesc, privacy: .public)")
            }

            // Analyze this service as a candidate
            await analyzeServiceCandidate(service: service, characteristics: characteristics, peripheral: peripheral)
        }
    }

    private func analyzeServiceCandidate(service: CBService, characteristics: [CBCharacteristic], peripheral: CBPeripheral) async {
        // Look for write and notify characteristics
        var foundWrite: CBCharacteristic?
        var foundNotify: CBCharacteristic?

        for characteristic in characteristics {
            let properties = characteristic.properties

            // Look for a characteristic with write properties
            if properties.contains(.write) || properties.contains(.writeWithoutResponse) {
                foundWrite = characteristic
            }

            // Look for a characteristic with notify property
            if properties.contains(.notify) || properties.contains(.indicate) {
                foundNotify = characteristic
            }
        }

        // Calculate score for this service (higher is better)
        let score = calculateServiceScore(
            service: service,
            hasWrite: foundWrite != nil,
            hasNotify: foundNotify != nil,
            writeChar: foundWrite,
            notifyChar: foundNotify
        )

        Logger.bluetooth.debug("📊 Service \(service.uuid.uuidString, privacy: .public) score: \(score)")

        // If this service has both write and notify, consider it
        if let write = foundWrite, let notify = foundNotify {
            // If we don't have a service yet, or this one has an equal/better score
            let shouldUseThisService = proprietaryService == nil || score >= getCurrentServiceScore()

            if shouldUseThisService {
                Logger.bluetooth.info("✅ Selected service: \(service.uuid.uuidString, privacy: .public)")

                proprietaryService = service
                writeCharacteristic = write
                notifyCharacteristic = notify

                Logger.bluetooth.info("✍️ Write characteristic: \(write.uuid.uuidString, privacy: .public)")
                Logger.bluetooth.info("🔔 Notify characteristic: \(notify.uuid.uuidString, privacy: .public)")
            }
        }

        await handleServiceChecked()
    }

    private func calculateServiceScore(
        service: CBService,
        hasWrite: Bool,
        hasNotify: Bool,
        writeChar: CBCharacteristic?,
        notifyChar: CBCharacteristic?
    ) -> Int {
        var score = 0

        // Must have both write and notify
        guard hasWrite && hasNotify else { return -1 }

        score += 100 // Base score for having both

        let serviceUUID = service.uuid.uuidString.uppercased()

        // Prefer 0xFDxx services (common for proprietary)
        if serviceUUID.hasPrefix("FD") && serviceUUID.count == 4 {
            score += 50
        }

        // Prefer 128-bit UUIDs (very likely proprietary)
        if serviceUUID.count > 8 {
            score += 30
        }

        // Strongly prefer known Nothing/CMF proprietary services
        if let bonus = preferredProprietaryServices[serviceUUID] {
            score += bonus
        }

        // Prefer .write over .writeWithoutResponse
        if let write = writeChar, write.properties.contains(.write) {
            score += 10
        }

        // Prefer .notify over .indicate
        if let notify = notifyChar, notify.properties.contains(.notify) {
            score += 10
        }

        return score
    }

    private func getCurrentServiceScore() -> Int {
        guard let service = proprietaryService,
              let write = writeCharacteristic,
              let notify = notifyCharacteristic else {
            return -1
        }

        return calculateServiceScore(
            service: service,
            hasWrite: true,
            hasNotify: true,
            writeChar: write,
            notifyChar: notify
        )
    }

    private func handleServiceChecked() async {
        servicesChecked += 1

        // Check if we've analyzed all candidate services
        if servicesChecked >= servicesToCheck {
            if let service = proprietaryService,
               writeCharacteristic != nil,
               let notify = notifyCharacteristic,
               let peripheral = connectedPeripheral {

                Logger.bluetooth.info("🚀 Communication channels established with service \(service.uuid.uuidString, privacy: .public)")

                // Enable notifications
                peripheral.setNotifyValue(true, for: notify)

                // Start device status refresh
                refreshDeviceStatus()
            } else {
                Logger.bluetooth.error("❌ Failed to find suitable proprietary service with write+notify characteristics")
                callback.onError(.connectionFailed)
            }
        }
    }

    // Helper function to describe characteristic properties
    private func describeProperties(_ properties: CBCharacteristicProperties) -> String {
        var props: [String] = []
        if properties.contains(.read) { props.append("read") }
        if properties.contains(.write) { props.append("write") }
        if properties.contains(.writeWithoutResponse) { props.append("writeWithoutResponse") }
        if properties.contains(.notify) { props.append("notify") }
        if properties.contains(.indicate) { props.append("indicate") }
        return props.joined(separator: ", ")
    }

    nonisolated public func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard error == nil, let data = characteristic.value else {
            return
        }

        Task { @MainActor in
            processResponse(data)
        }
    }

    nonisolated public func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard error != nil else {
            return
        }

        Task { @MainActor in
            callback.onError(.connectionFailed)
        }
    }
}

// MARK: Connection Error

extension ConnectionError {

    public var errorDescription: String? {
        switch self {
            case .bluetooth(.poweredOff):
                return "Bluetooth is powered off"
            case .bluetooth(.unauthorized):
                return "Bluetooth is not authorized"
            case .bluetooth(.unavailable):
                return "Bluetooth is not available on this device"
            case .deviceNotFound:
                return "Nothing device is not found"
            case .connectionFailed:
                return "Failed to connect to device"
            case .invalidResponse:
                return "Received invalid response from device"
            case .unsupportedOperation:
                return "Operation not supported by this device model"
            case .timeout:
                return "Operation timed out"
        }
    }
}
