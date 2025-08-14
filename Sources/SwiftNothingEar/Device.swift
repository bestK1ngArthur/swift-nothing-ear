@preconcurrency import CoreBluetooth
import Combine
import Foundation
import IOBluetooth
import os.log

extension NothingEar {

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
        let onUpdateANCMode: (ANCMode?) -> Void
        let onUpdateEnhancedBass: (EnhancedBassSettings?) -> Void
        let onUpdateEQPreset: (EQPreset?) -> Void
        let onUpdateDeviceSettings: (DeviceSettings) -> Void

        let onError: (ConnectionError) -> Void

        public init(
            onDiscover: @escaping (CBPeripheral) -> Void,
            onConnect: @escaping (Result<DeviceInfo, Error>) -> Void,
            onDisconnect: @escaping (Result<Void, Error>) -> Void,
            onUpdateBattery: @escaping (Battery?) -> Void,
            onUpdateANCMode: @escaping (ANCMode?) -> Void,
            onUpdateEnhancedBass: @escaping (EnhancedBassSettings?) -> Void,
            onUpdateEQPreset: @escaping (EQPreset?) -> Void,
            onUpdateDeviceSettings: @escaping (DeviceSettings) -> Void,
            onError: @escaping (ConnectionError) -> Void
        ) {
            self.onDiscover = onDiscover
            self.onConnect = onConnect
            self.onDisconnect = onDisconnect
            self.onUpdateBattery = onUpdateBattery
            self.onUpdateANCMode = onUpdateANCMode
            self.onUpdateEnhancedBass = onUpdateEnhancedBass
            self.onUpdateEQPreset = onUpdateEQPreset
            self.onUpdateDeviceSettings = onUpdateDeviceSettings
            self.onError = onError
        }
    }

    @MainActor
    public final class Device: NSObject {

        public private(set) var connectionStatus: ConnectionStatus = .disconnected

        public private(set) var deviceInfo: DeviceInfo?
        public private(set) var deviceSettings: DeviceSettings?

        public private(set) var battery: Battery?
        public private(set) var ancMode: ANCMode?
        public private(set) var enhancedBass: EnhancedBassSettings?
        public private(set) var eqPreset: EQPreset?

        private let callback: Callback

        private nonisolated(unsafe) var centralManager: CBCentralManager!
        private nonisolated(unsafe) var connectedPeripheral: CBPeripheral?
        private nonisolated(unsafe) var serviceIds: ServiceUUID?

        private nonisolated(unsafe) var writeCharacteristic: CBCharacteristic?
        private nonisolated(unsafe) var readCharacteristic: CBCharacteristic?
        private nonisolated(unsafe) var notifyCharacteristic: CBCharacteristic?

        private var operationID: UInt8 = 1
        private var pendingOperations: [UInt8: (Data) -> Void] = [:]

        public init(_ callback: Callback) {
            self.callback = callback
            super.init()
            self.centralManager = CBCentralManager(delegate: self, queue: nil)
        }
    }
}

// MARK: Public Interface

extension NothingEar.Device {

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
        centralManager.scanForPeripherals(withServices: allServiceIds, options: nil)
    }

    public func stopScanning() {
        centralManager.stopScan()

        if connectionStatus == .scanning {
            connectionStatus = .disconnected
        }
    }

    @discardableResult
    public func checkAndConnectToExistingDevices() -> Bool {
        let connectedPeripherals = centralManager.retrieveConnectedPeripherals(withServices: allServiceIds)

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

    public func setANCMode(_ mode: NothingEar.ANCMode) {
        guard isConnected else {
            callback.onError(.connectionFailed)
            return
        }

        guard
            let deviceInfo,
            deviceInfo.model.supportsANC
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

    public func setEnhancedBass(_ settings: NothingEar.EnhancedBassSettings) {
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

    public func setEQPreset(_ preset: NothingEar.EQPreset) {
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

        guard
            let deviceInfo,
            deviceInfo.model.supportsInEarDetection
        else {
            callback.onError(.unsupportedOperation)
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

    public func setGesture(
        type: NothingEar.GestureType,
        action: NothingEar.GestureAction,
        device: NothingEar.GestureDevice? = nil
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
}

// MARK: Private Methods

extension NothingEar.Device {

    private var allServiceIds: [CBUUID] {
        NothingEar.ServiceUUID.all.map { $0.uuid }
    }

    private func refreshDeviceStatus() {
        guard isConnected else { return }

        let tasks: [() -> Void] = [
            // Request device info
            sendReadSerialNumberRequest,
            sendReadFirmwareRequest,

            // Request device settings
            sendReadInEarRequest,
            sendReadLowLatencyRequest,

            // Request other info
            sendEnhancedBassRequest,
            sendReadANCRequest,
            sendReadEQRequest,
            sendReadBatteryRequest,
            sendReadGestureRequest
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
        NothingEar.Logger.bluetooth.debug("🔋 Sending read battery request")

        let request = NothingEar.BluetoothRequest(
            command: NothingEar.BluetoothCommand.RequestRead.battery,
            payload: [],
            operationID: nextOperationID()
        )
        sendRequest(request)
    }

    private func sendReadANCRequest() {
        guard
            let deviceInfo = deviceInfo,
            deviceInfo.model.supportsANC
        else {
            return
        }

        NothingEar.Logger.bluetooth.debug("🔇 Sending read ANC request")

        let request = NothingEar.BluetoothRequest(
            command: NothingEar.BluetoothCommand.RequestRead.anc,
            payload: [],
            operationID: nextOperationID()
        )
        sendRequest(request)
    }

    private func sendReadEQRequest() {
        NothingEar.Logger.bluetooth.debug("🎵 Sending read EQ request")

        let isListeningModeSupported = if case .cmfBudsPro2 = deviceInfo?.model {
            true
        } else if case .cmfBuds = deviceInfo?.model {
            true
        } else {
            false
        }
        let command = isListeningModeSupported
            ? NothingEar.BluetoothCommand.RequestRead.listeningMode
            : NothingEar.BluetoothCommand.RequestRead.eq
        let request = NothingEar.BluetoothRequest(
            command: command,
            payload: [],
            operationID: nextOperationID()
        )
        sendRequest(request)
    }

    private func sendReadFirmwareRequest() {
        NothingEar.Logger.bluetooth.debug("💾 Sending read firmware request")

        let request = NothingEar.BluetoothRequest(
            command: NothingEar.BluetoothCommand.RequestRead.firmware,
            payload: [],
            operationID: nextOperationID()
        )
        sendRequest(request)
    }

    private func sendReadInEarRequest() {
        guard
            let deviceInfo = deviceInfo,
            deviceInfo.model.supportsInEarDetection
        else {
            return
        }

        NothingEar.Logger.bluetooth.debug("👂 Sending in-ear detection request")

        let request = NothingEar.BluetoothRequest(
            command: NothingEar.BluetoothCommand.RequestRead.inEarDetection,
            payload: [],
            operationID: nextOperationID()
        )
        sendRequest(request)
    }

    private func sendReadLowLatencyRequest() {
        NothingEar.Logger.bluetooth.debug("⚡ Sending read latency request")

        let request = NothingEar.BluetoothRequest(
            command: NothingEar.BluetoothCommand.RequestRead.lowLatency,
            payload: [],
            operationID: nextOperationID()
        )
        sendRequest(request)
    }

    private func sendEnhancedBassRequest() {
        NothingEar.Logger.bluetooth.debug("🎶 Sending read enhanced bass request")

        let request = NothingEar.BluetoothRequest(
            command: NothingEar.BluetoothCommand.RequestRead.enhancedBass,
            payload: [],
            operationID: nextOperationID()
        )
        sendRequest(request)
    }

    private func sendReadGestureRequest() {
        NothingEar.Logger.bluetooth.debug("👆 Sending read gesture request")

        let request = NothingEar.BluetoothRequest(
            command: NothingEar.BluetoothCommand.RequestRead.gesture,
            payload: [],
            operationID: nextOperationID()
        )
        sendRequest(request)
    }

    private func sendReadSerialNumberRequest() {
        NothingEar.Logger.bluetooth.debug("🏷️ Sending read serial number request")

        let request = NothingEar.BluetoothRequest(
            command: NothingEar.BluetoothCommand.RequestRead.serialNumber,
            payload: [],
            operationID: nextOperationID()
        )
        sendRequest(request)
    }

    private func sendRequest(_ request: NothingEar.BluetoothRequest) {
        guard
            let connectedPeripheral,
            let writeCharacteristic
        else {
            callback.onError(.connectionFailed)
            return
        }

        let data = Data(request.toBytes())
        NothingEar.Logger.logBluetoothData(Array(data), direction: .outgoing)
        connectedPeripheral.writeValue(data, for: writeCharacteristic, type: .withResponse)
    }

    private func processResponse(_ data: Data) {
        NothingEar.Logger.logBluetoothData(Array(data), direction: .incoming)

        guard let response = NothingEar.BluetoothResponse(data: Array(data)) else {
            callback.onError(.invalidResponse)
            return
        }

        switch response.command {
            case NothingEar.BluetoothCommand.Response.serialNumber:
                if let serialNumber = response.parseSerialNumber(),
                   let detectedModel = NothingEar.Model.getModel(fromSerialNumber: serialNumber) {
                    updateDeviceInfo { deviceInfo in
                        deviceInfo.model = detectedModel
                        deviceInfo.serialNumber = serialNumber
                    }
                    NothingEar.Logger.parsing.info("🏷️ Parsed device info: model=\(detectedModel.code, privacy: .public), serial=\(serialNumber, privacy: .public)")
                } else {
                    NothingEar.Logger.parsing.warning("🏷️ Failed to parse serial number from response")
                }

            case NothingEar.BluetoothCommand.Response.firmware:
                let firmwareVersion = response.parseFirmwareVersion()
                if !firmwareVersion.isEmpty {
                    updateDeviceInfo { deviceInfo in
                        deviceInfo.firmwareVersion = firmwareVersion
                    }
                    NothingEar.Logger.parsing.info("💾 Parsed firmware version: \(firmwareVersion, privacy: .public)")

                    if let deviceInfo {
                        callback.onConnect(.success(deviceInfo))
                    }
                } else {
                    NothingEar.Logger.parsing.warning("💾 Failed to parse firmware version")
                }

            case NothingEar.BluetoothCommand.Response.batteryA,
                NothingEar.BluetoothCommand.Response.batteryB:
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
                    NothingEar.Logger.parsing.info("🔋 Parsed battery: \(batteryDescription, privacy: .public)")
                } else {
                    NothingEar.Logger.parsing.warning("🔋 Failed to parse battery data")
                }

            case NothingEar.BluetoothCommand.Response.ancA,
                NothingEar.BluetoothCommand.Response.ancB:
                if let ancMode = response.parseANCMode() {
                    self.ancMode = ancMode
                    callback.onUpdateANCMode(ancMode)
                    NothingEar.Logger.parsing.info("🔇 Parsed ANC mode: \(String(describing: ancMode), privacy: .public)")
                } else {
                    NothingEar.Logger.parsing.warning("🔇 Failed to parse ANC mode")
                }

            case NothingEar.BluetoothCommand.Response.eqA,
                NothingEar.BluetoothCommand.Response.eqB:
                if let eqPreset = response.parseEQPreset() {
                    self.eqPreset = eqPreset
                    callback.onUpdateEQPreset(eqPreset)
                    NothingEar.Logger.parsing.info("🎵 Parsed EQ preset: \(String(describing: eqPreset), privacy: .public)")
                } else {
                    NothingEar.Logger.parsing.warning("🎵 Failed to parse EQ preset")
                }

            case NothingEar.BluetoothCommand.Response.inEarDetection:
                if let deviceInfo,
                   deviceInfo.model.supportsInEarDetection,
                   let inEarDetection = response.parseInEarDetection() {
                    updateDeviceSettings { settings in
                        settings.inEarDetection = inEarDetection
                    }
                    NothingEar.Logger.parsing.info("👂 Parsed in-ear detection: \(inEarDetection ? "enabled" : "disabled", privacy: .public)")
                } else {
                    NothingEar.Logger.parsing.warning("👂 Failed to parse in-ear detection or unsupported by device")
                }

            case NothingEar.BluetoothCommand.Response.lowLatency:
                if let lowLatency = response.parseLowLatency() {
                    updateDeviceSettings { settings in
                        settings.lowLatency = lowLatency
                    }
                    NothingEar.Logger.parsing.info("⚡ Parsed low latency: \(lowLatency ? "enabled" : "disabled", privacy: .public)")
                } else {
                    NothingEar.Logger.parsing.warning("⚡ Failed to parse low latency setting")
                }

            case NothingEar.BluetoothCommand.Response.enhancedBass:
                if let enhancedBass = response.parseEnhancedBassSettings() {
                    self.enhancedBass = enhancedBass
                    callback.onUpdateEnhancedBass(enhancedBass)
                    NothingEar.Logger.parsing.info("🎶 Parsed enhanced bass: \(enhancedBass.isEnabled ? "enabled" : "disabled", privacy: .public)")
                } else {
                    NothingEar.Logger.parsing.warning("🎶 Failed to parse enhanced bass settings")
                }

            case NothingEar.BluetoothCommand.Response.gesture:
                let gestures = response.parseGestures()
                if !gestures.isEmpty {
                    NothingEar.Logger.parsing.info("👆 Parsed gestures: \(gestures.count, privacy: .public) gesture(s)")
                } else {
                    NothingEar.Logger.parsing.warning("👆 No gestures parsed from response")
                }
                default:
                NothingEar.Logger.parsing.warning("❓ Unknown response: command = \(response.command, privacy: .public), payload = \(response.payload.map { String(format: "%02X", $0) } .joined(separator: " "), privacy: .public)")
        }
    }

    private func updateDeviceInfo(_ update: (inout NothingEar.DeviceInfo) -> Void) {
        if deviceInfo == nil {
            self.deviceInfo = .empty
        }

        update(&deviceInfo!)
    }

    private func updateDeviceSettings(_ update: (inout NothingEar.DeviceSettings) -> Void) {
        if deviceSettings == nil {
            self.deviceSettings = .default
        }

        update(&deviceSettings!)

        if let deviceSettings {
            callback.onUpdateDeviceSettings(deviceSettings)
        }
    }

    private func error(from state: CBManagerState) -> NothingEar.ConnectionError? {
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

extension NothingEar.Device: CBCentralManagerDelegate {

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
            callback.onDiscover(peripheral)
        }
    }

    nonisolated public func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        Task { @MainActor in
            connectionStatus = .connected

            peripheral.delegate = self
            peripheral.discoverServices(allServiceIds)

            if let paired = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] {
                for device in paired where device.name == peripheral.name {
                    if let address = device.addressString {
                        let bluetoothAddress = address
                            .replacingOccurrences(of: "-", with: ":")
                            .uppercased()
                        updateDeviceInfo { deviceInfo in
                            deviceInfo.bluetoothAddress = bluetoothAddress
                        }
                    }
                }
            }
        }
    }

    nonisolated public func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        Task { @MainActor in
            connectionStatus = .disconnected

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
        writeCharacteristic = nil
        readCharacteristic = nil

        Task { @MainActor in
            connectionStatus = .disconnected

            if let error {
                callback.onDisconnect(.failure(error))
            } else {
                callback.onDisconnect(.success(()))
            }
        }
    }
}

// MARK: CBPeripheralDelegate

extension NothingEar.Device: CBPeripheralDelegate {

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

        // Determine device type and configure UUIDs
        for service in peripheral.services ?? [] {
            for serviceIds in NothingEar.ServiceUUID.all where service.uuid == serviceIds.uuid {
                self.serviceIds = serviceIds

                let characteristicUUIDs = [serviceIds.writeCharacteristicUUID, serviceIds.notifyCharacteristicUUID]
                peripheral.discoverCharacteristics(characteristicUUIDs, for: service)

                break
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

        guard let serviceIds else { return }

        for characteristic in service.characteristics ?? [] {
            if characteristic.uuid == serviceIds.writeCharacteristicUUID {
                writeCharacteristic = characteristic
                readCharacteristic = characteristic // For backward compatibility
            } else if characteristic.uuid == serviceIds.notifyCharacteristicUUID {
                notifyCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)

                // Start initial device status request
                Task { @MainActor in
                    refreshDeviceStatus()
                }
                break
            }
        }
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

extension NothingEar.ConnectionError {

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
