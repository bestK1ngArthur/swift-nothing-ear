@preconcurrency import CoreBluetooth
import XCTest
@testable import SwiftNothingEar

@MainActor
final class DeviceConnectionTests: XCTestCase {

    func testNotificationFromInactiveSessionDoesNotUpdateANC() {
        var reportedModes: [NoiseCancellationMode?] = []
        let callback = Callback(
            onDiscover: { _ in },
            onConnect: { _ in },
            onDisconnect: { _ in },
            onUpdateBattery: { _ in },
            onUpdateANCMode: { reportedModes.append($0) },
            onUpdateSpatialAudio: { _ in },
            onUpdateEnhancedBass: { _ in },
            onUpdateEQPreset: { _ in },
            onUpdateDeviceSettings: { _ in },
            onUpdateRingBuds: { _ in },
            onError: { _ in }
        )
        let device = Device(callback, initializesBluetooth: false)

        // Synthetic lifecycle fixture: a queued notification arrives with no active session.
        // The ANC bytes are the existing Ear (2024) capture in NothingEarTests.testANC.
        let capturedANC = Data([
            0x55, 0x60, 0x01, 0x1E, 0x40, 0x02, 0x00, 0x01,
            0x00, 0x03
        ])
        device.processNotification(capturedANC, from: UUID())

        XCTAssertNil(device.ancMode)
        XCTAssertTrue(reportedModes.isEmpty)
    }

    func testConnectionCleanupCancelsDelayedInitialization() async throws {
        let callback = Callback(
            onDiscover: { _ in },
            onConnect: { _ in },
            onDisconnect: { _ in },
            onUpdateBattery: { _ in },
            onUpdateANCMode: { _ in },
            onUpdateSpatialAudio: { _ in },
            onUpdateEnhancedBass: { _ in },
            onUpdateEQPreset: { _ in },
            onUpdateDeviceSettings: { _ in },
            onUpdateRingBuds: { _ in },
            onError: { _ in }
        )
        let device = Device(callback, initializesBluetooth: false)
        let delayedAction = expectation(description: "stale initialization action")
        delayedAction.isInverted = true

        // Synthetic lifecycle fixture: use the production delayed-request scheduler,
        // then run the same cleanup used by the Core Bluetooth disconnect callbacks.
        device.runTasks([{}, { delayedAction.fulfill() }], delay: 0.05)
        device.clearConnectionState()
        await fulfillment(of: [delayedAction], timeout: 1)
    }

    func testCurrentInitializationTasksStillRun() async throws {
        let callback = Callback(
            onDiscover: { _ in }, onConnect: { _ in }, onDisconnect: { _ in },
            onUpdateBattery: { _ in }, onUpdateANCMode: { _ in },
            onUpdateSpatialAudio: { _ in }, onUpdateEnhancedBass: { _ in },
            onUpdateEQPreset: { _ in }, onUpdateDeviceSettings: { _ in },
            onUpdateRingBuds: { _ in }, onError: { _ in }
        )
        let device = Device(callback, initializesBluetooth: false)
        let currentAction = expectation(description: "current initialization action")

        // Synthetic lifecycle fixture: exercise the active generation of the
        // production initialization scheduler without a hardware peripheral.
        device.beginConnectionSession(for: UUID())
        device.runTasks([{}, { currentAction.fulfill() }], delay: 0.02)
        await fulfillment(of: [currentAction], timeout: 2)
    }

    func testReconnectDropsOldInitializationAndRunsCurrentTasks() async throws {
        let device = Device(noOpCallback(), initializesBluetooth: false)
        let identifier = UUID()
        let oldAction = expectation(description: "old session action")
        oldAction.isInverted = true
        let currentAction = expectation(description: "new session action")

        // Synthetic lifecycle fixture: reuse one identifier across two sessions
        // through the same production session and task scheduling paths.
        device.beginConnectionSession(for: identifier)
        device.runTasks([{}, { oldAction.fulfill() }], delay: 0.05)
        device.beginConnectionSession(for: identifier)
        device.runTasks([{}, { currentAction.fulfill() }], delay: 0.02)
        await fulfillment(of: [currentAction, oldAction], timeout: 2)
    }

    func testSamePeripheralOldGenerationNotificationIsIgnored() {
        var reportedModes: [NoiseCancellationMode?] = []
        let device = Device(noOpCallback(onANC: { reportedModes.append($0) }), initializesBluetooth: false)
        let identifier = UUID()
        let capturedANC = Data([
            0x55, 0x60, 0x01, 0x1E, 0x40, 0x02, 0x00, 0x01,
            0x00, 0x03
        ])

        // Synthetic lifecycle fixture: a queued callback retains the old generation
        // while the same peripheral identifier starts a new active session.
        // The ANC bytes are the existing Ear (2024) capture in NothingEarTests.testANC.
        let oldGeneration = device.beginConnectionSession(for: identifier)
        device.markSessionConnected()
        let currentGeneration = device.beginConnectionSession(for: identifier)
        device.markSessionConnected()

        device.processNotification(capturedANC, from: identifier, generation: oldGeneration)
        device.processNotification(capturedANC, from: UUID(), generation: currentGeneration)
        XCTAssertNil(device.ancMode)
        XCTAssertTrue(reportedModes.isEmpty)

        device.processNotification(capturedANC, from: identifier, generation: currentGeneration)
        XCTAssertEqual(device.ancMode, .active(.low))
        XCTAssertEqual(reportedModes, [NoiseCancellationMode.active(.low)])
    }

    func testHandshakeWaitsForNotificationSubscription() {
        let callback = Callback(
            onDiscover: { _ in }, onConnect: { _ in }, onDisconnect: { _ in },
            onUpdateBattery: { _ in }, onUpdateANCMode: { _ in },
            onUpdateSpatialAudio: { _ in }, onUpdateEnhancedBass: { _ in },
            onUpdateEQPreset: { _ in }, onUpdateDeviceSettings: { _ in },
            onUpdateRingBuds: { _ in }, onError: { _ in }
        )
        let device = Device(callback, initializesBluetooth: false)
        var events: [String] = []

        // Synthetic lifecycle fixture: these closures stand in for the real
        // setNotifyValue and initial handshake calls at the production completion seam.
        device.completeCommunicationSetup(
            enableNotifications: { events.append("subscribe") },
            beginHandshake: { events.append("handshake") }
        )

        XCTAssertEqual(events, ["subscribe"])
    }

    func testSuccessfulSubscriptionStartsHandshakeOnlyOnce() {
        let device = Device(noOpCallback(), initializesBluetooth: false)
        var events: [String] = []

        // Synthetic lifecycle fixture through the production completion seam.
        device.beginConnectionSession(for: UUID())
        device.markSessionConnected()
        device.completeCommunicationSetup(
            enableNotifications: { events.append("subscribe") },
            beginHandshake: { events.append("handshake") }
        )
        device.completeNotificationSubscription(isNotifying: true)
        device.completeNotificationSubscription(isNotifying: true)

        XCTAssertEqual(events, ["subscribe", "handshake"])
    }

    func testFailedSubscriptionClearsPendingHandshakeAndReportsOnce() {
        for (isNotifying, hadError) in [(false, false), (true, true)] {
            var errors = 0
            let device = Device(noOpCallback(onError: { error in
                if case .connectionFailed = error { errors += 1 }
            }), initializesBluetooth: false)
            var events: [String] = []

            // Synthetic lifecycle fixture: notification state is off or Core Bluetooth
            // reports an error, followed by a late success callback.
            device.beginConnectionSession(for: UUID())
            device.markSessionConnected()
            device.completeCommunicationSetup(
                enableNotifications: { events.append("subscribe") },
                beginHandshake: { events.append("handshake") }
            )
            device.completeNotificationSubscription(isNotifying: isNotifying, hadError: hadError)
            device.completeNotificationSubscription(isNotifying: true)

            XCTAssertEqual(events, ["subscribe"])
            XCTAssertEqual(errors, 1)
            XCTAssertTrue(device.connectionStatus == .disconnected)
        }
    }

    func testSubscriptionFailureCallbackCanStartNewSession() {
        let nextIdentifier = UUID()
        var reconnect: (() -> Void)?
        let device = Device(noOpCallback(onError: { _ in reconnect?() }), initializesBluetooth: false)
        reconnect = { [weak device] in
            _ = device?.beginConnectionSession(for: nextIdentifier)
        }

        // Synthetic lifecycle fixture: onError reenters Device while a failed
        // subscription is being retired.
        device.beginConnectionSession(for: UUID())
        device.markSessionConnected()
        device.completeCommunicationSetup(enableNotifications: {}, beginHandshake: {})
        device.completeNotificationSubscription(isNotifying: false)

        XCTAssertTrue(device.connectionStatus == .connecting)
        reconnect = nil
    }

    func testInitialSetupSilenceTimesOutOnceFromConnect() async throws {
        for phase in ["connect", "discovery", "subscription"] {
            var timeouts = 0
            var otherErrors = 0
            var handshakes = 0
            let timeoutEvent = expectation(description: "\(phase) setup deadline")
            let device = Device(noOpCallback(onError: { error in
                if case .timeout = error {
                    timeouts += 1
                    timeoutEvent.fulfill()
                }
                else { otherErrors += 1 }
            }), initializesBluetooth: false)
            device.setupTimeoutNanoseconds = 20_000_000

            // Synthetic lifecycle fixtures exercise the real session start and
            // subscription seams without a constructible CBPeripheral.
            device.beginConnectionSession(for: UUID())
            if phase != "connect" { device.markSessionConnected() }
            if phase == "subscription" {
                device.completeCommunicationSetup(
                    enableNotifications: {},
                    beginHandshake: { handshakes += 1 }
                )
            }

            await fulfillment(of: [timeoutEvent], timeout: 2)
            device.completeNotificationSubscription(isNotifying: true)

            XCTAssertEqual(timeouts, 1, "phase: \(phase)")
            XCTAssertEqual(otherErrors, 0, "phase: \(phase)")
            XCTAssertEqual(handshakes, 0, "phase: \(phase)")
            XCTAssertTrue(device.connectionStatus == .disconnected, "phase: \(phase)")
        }
    }

    func testReplacementAfterCompletedHandshakeStillHasSetupDeadline() async throws {
        var connections = 0
        var timeouts = 0
        let timeoutEvent = expectation(description: "replacement session timeout")
        let device = Device(noOpCallback(
            onConnect: { result in
                if case .success = result { connections += 1 }
            },
            onError: { error in
                if case .timeout = error {
                    timeouts += 1
                    timeoutEvent.fulfill()
                }
            }
        ), initializesBluetooth: false)
        device.setupTimeoutNanoseconds = 20_000_000

        // Existing captured Ear (2024) config response from
        // NothingEarTests.testDeviceConfigUsesBluetoothAddressWhenSerialIsEmpty.
        let capturedIdentity: [UInt8] = [
            0x55, 0x60, 0x01, 0x06, 0x40, 0x57, 0x00, 0x02,
            0x09, 0x32, 0x2C, 0x31, 0x2C, 0x0A, 0x32, 0x2C,
            0x32, 0x2C, 0x31, 0x2E, 0x30, 0x2E, 0x31, 0x2E,
            0x35, 0x36, 0x0A, 0x32, 0x2C, 0x34, 0x2C, 0x0A,
            0x33, 0x2C, 0x31, 0x2C, 0x0A, 0x33, 0x2C, 0x32,
            0x2C, 0x31, 0x2E, 0x30, 0x2E, 0x31, 0x2E, 0x35,
            0x36, 0x0A, 0x33, 0x2C, 0x34, 0x2C, 0x0A, 0x34,
            0x2C, 0x31, 0x2C, 0x0A, 0x34, 0x2C, 0x32, 0x2C,
            0x31, 0x2E, 0x30, 0x2E, 0x31, 0x2E, 0x35, 0x36,
            0x0A, 0x34, 0x2C, 0x34, 0x2C, 0x0A, 0x33, 0x2C,
            0x36, 0x2C, 0x37, 0x41, 0x31, 0x39, 0x44, 0x33,
            0x34, 0x46, 0x42, 0x38, 0x32, 0x36, 0x0A
        ]
        // Synthetic firmware response envelope: its version text comes from the
        // captured config above; this envelope is not a captured packet.
        let syntheticFirmware = [UInt8(0x55), 0x60, 0x01, 0x42, 0x40, 0x08, 0x00, 0x02]
            + Array("1.0.1.56".utf8)

        device.beginConnectionSession(for: UUID())
        device.markSessionConnected()
        device.processResponse(Data(capturedIdentity), deviceName: "Nothing Ear")
        device.processResponse(Data(syntheticFirmware))
        XCTAssertEqual(connections, 1)
        XCTAssertEqual(device.deviceInfo?.model, .ear(.black))
        XCTAssertEqual(device.deviceInfo?.firmwareVersion, "1.0.1.56")

        // Synthetic lifecycle fixture: connect(to:) uses this same session start
        // when replacing a previously initialized peripheral without cleanup.
        device.beginConnectionSession(for: UUID())
        await fulfillment(of: [timeoutEvent], timeout: 2)

        XCTAssertEqual(timeouts, 1)
        XCTAssertTrue(device.connectionStatus == .disconnected)
    }

    func testRapidPowerRecoveryProcessesCurrentPoweredOnState() {
        let device = Device(noOpCallback(), initializesBluetooth: false)
        let generation = device.beginConnectionSession(for: UUID())
        var discoveryChecks = 0

        // Synthetic lifecycle fixture: poweredOff and poweredOn were both
        // delivered before their queued MainActor completions ran. The manager
        // is powered on by the time either completion is processed.
        device.processCentralStateUpdate(
            observedState: .poweredOff,
            generation: generation,
            currentState: { .poweredOn },
            onPoweredOn: { discoveryChecks += 1 }
        )
        device.processCentralStateUpdate(
            observedState: .poweredOn,
            generation: generation,
            currentState: { .poweredOn },
            onPoweredOn: { discoveryChecks += 1 }
        )

        XCTAssertEqual(discoveryChecks, 1)
    }

    func testStalePoweredOnCallbackDoesNotDiscoverWhileManagerIsOff() {
        let device = Device(noOpCallback(), initializesBluetooth: false)
        let generation = device.beginConnectionSession(for: UUID())
        var discoveryChecks = 0

        // Synthetic lifecycle fixture: the queued poweredOn callback is stale
        // because the manager has since moved to poweredOff.
        device.processCentralStateUpdate(
            observedState: .poweredOn,
            generation: generation,
            currentState: { .poweredOff },
            onPoweredOn: { discoveryChecks += 1 }
        )

        XCTAssertEqual(discoveryChecks, 0)
    }

    func testSetupFailureReportsOnceAndEndsSession() async throws {
        var errors = 0
        let duplicateError = expectation(description: "duplicate setup error")
        duplicateError.isInverted = true
        let device = Device(noOpCallback(onError: { error in
            if case .connectionFailed = error {
                errors += 1
                if errors > 1 { duplicateError.fulfill() }
            }
        }), initializesBluetooth: false)
        device.setupTimeoutNanoseconds = 20_000_000

        // Synthetic lifecycle fixture: this production failure path is shared
        // by service, characteristic, subscription, and setup deadline failures.
        device.beginConnectionSession(for: UUID())
        device.markSessionConnected()
        device.failInitialSetup(.connectionFailed)
        device.failInitialSetup(.connectionFailed)
        await fulfillment(of: [duplicateError], timeout: 0.2)

        XCTAssertEqual(errors, 1)
        XCTAssertTrue(device.connectionStatus == .disconnected)
    }

    func testQueuedDisconnectCannotClearNewSession() {
        var disconnects = 0
        let device = Device(noOpCallback(onDisconnect: { _ in disconnects += 1 }), initializesBluetooth: false)
        let identifier = UUID()

        // Synthetic lifecycle fixture: an old MainActor completion arrives
        // after the same identifier started a new active session.
        let oldGeneration = device.beginConnectionSession(for: identifier)
        device.markSessionConnected()
        let currentGeneration = device.beginConnectionSession(for: identifier)
        device.markSessionConnected()
        device.completeDisconnection(from: identifier, generation: oldGeneration, name: "synthetic", error: nil)
        device.completeDisconnection(from: UUID(), generation: currentGeneration, name: "synthetic", error: nil)

        XCTAssertTrue(device.connectionStatus == .connected)
        XCTAssertEqual(disconnects, 0)

        device.completeDisconnection(from: identifier, generation: currentGeneration, name: "synthetic", error: nil)
        XCTAssertTrue(device.connectionStatus == .disconnected)
        XCTAssertEqual(disconnects, 1)
    }

    func testClientDisconnectAndTerminalReceiptBothOrdersFinishCleanup() {
        for terminalReceiptFirst in [true, false] {
            let identifier = UUID()
            var disconnects = 0
            var cancellations = 0
            let device = Device(noOpCallback(onDisconnect: { _ in disconnects += 1 }), initializesBluetooth: false)

            // Synthetic lifecycle fixture through the production terminal receipt,
            // public disconnect cancellation path, and queued MainActor completion.
            device.beginConnectionSession(for: identifier)
            device.markSessionConnected()
            let terminalGeneration: UInt64
            if terminalReceiptFirst {
                terminalGeneration = device.recordTerminalReceipt()
                device.requestDisconnection { cancellations += 1 }
            } else {
                device.requestDisconnection { cancellations += 1 }
                terminalGeneration = device.recordTerminalReceipt()
            }
            device.completeDisconnection(
                from: identifier,
                generation: terminalGeneration,
                name: "synthetic",
                error: nil
            )

            let order = terminalReceiptFirst ? "receipt then client" : "client then receipt"
            XCTAssertEqual(cancellations, terminalReceiptFirst ? 0 : 1, order)
            XCTAssertEqual(disconnects, 1, order)
            XCTAssertTrue(device.connectionStatus == .disconnected, order)
            XCTAssertFalse(Device.shouldIgnoreConnectionRequest(
                currentPeripheralIdentifier: identifier,
                requestedPeripheralIdentifier: identifier,
                connectionStatus: device.connectionStatus,
                peripheralState: .disconnected
            ), order)
        }
    }

    func testClientDisconnectAndFailedConnectReceiptBothOrdersFinishCleanup() {
        for terminalReceiptFirst in [true, false] {
            let identifier = UUID()
            var failures = 0
            var cancellations = 0
            let device = Device(noOpCallback(onConnect: { result in
                if case .failure = result { failures += 1 }
            }), initializesBluetooth: false)

            // Synthetic lifecycle fixture through the production didFailToConnect
            // receipt and queued MainActor completion paths.
            device.beginConnectionSession(for: identifier)
            let terminalGeneration: UInt64
            if terminalReceiptFirst {
                terminalGeneration = device.recordTerminalReceipt()
                device.requestDisconnection { cancellations += 1 }
            } else {
                device.requestDisconnection { cancellations += 1 }
                terminalGeneration = device.recordTerminalReceipt()
            }
            device.completeFailedConnection(
                from: identifier,
                generation: terminalGeneration,
                name: "synthetic",
                error: nil
            )

            let order = terminalReceiptFirst ? "receipt then client" : "client then receipt"
            XCTAssertEqual(cancellations, terminalReceiptFirst ? 0 : 1, order)
            XCTAssertEqual(failures, 1, order)
            XCTAssertTrue(device.connectionStatus == .disconnected, order)
            XCTAssertFalse(Device.shouldIgnoreConnectionRequest(
                currentPeripheralIdentifier: identifier,
                requestedPeripheralIdentifier: identifier,
                connectionStatus: device.connectionStatus,
                peripheralState: .disconnected
            ), order)
        }
    }

    func testRepeatedClientDisconnectCancelsOnceAndStillFinishesCleanup() {
        let identifier = UUID()
        var cancellations = 0
        var disconnects = 0
        let device = Device(noOpCallback(onDisconnect: { _ in disconnects += 1 }), initializesBluetooth: false)

        device.beginConnectionSession(for: identifier)
        device.markSessionConnected()
        device.requestDisconnection { cancellations += 1 }
        device.requestDisconnection { cancellations += 1 }
        let terminalGeneration = device.recordTerminalReceipt()
        device.completeDisconnection(
            from: identifier,
            generation: terminalGeneration,
            name: "synthetic",
            error: nil
        )

        XCTAssertEqual(cancellations, 1)
        XCTAssertEqual(disconnects, 1)
        XCTAssertTrue(device.connectionStatus == .disconnected)
    }

    func testTimeoutCallbackCanStartNewSession() async throws {
        var reconnect: (() -> Void)?
        var timeouts = 0
        let timeoutEvent = expectation(description: "first session timeout")
        let device = Device(noOpCallback(onError: { error in
            if case .timeout = error {
                timeouts += 1
                reconnect?()
                timeoutEvent.fulfill()
            }
        }), initializesBluetooth: false)
        reconnect = { [weak device] in
            device?.setupTimeoutNanoseconds = 1_000_000_000
            _ = device?.beginConnectionSession(for: UUID())
        }
        device.setupTimeoutNanoseconds = 20_000_000
        device.beginConnectionSession(for: UUID())

        await fulfillment(of: [timeoutEvent], timeout: 2)
        XCTAssertEqual(timeouts, 1)
        XCTAssertTrue(device.connectionStatus == .connecting)
        device.clearConnectionState()
        reconnect = nil
    }

    func testDuplicateConnectionRequestIsIgnoredWhileConnectingOrConnected() {
        let identifier = UUID()

        XCTAssertTrue(
            Device.shouldIgnoreConnectionRequest(
                currentPeripheralIdentifier: identifier,
                requestedPeripheralIdentifier: identifier,
                connectionStatus: .connecting,
                peripheralState: .disconnected
            )
        )
        XCTAssertTrue(
            Device.shouldIgnoreConnectionRequest(
                currentPeripheralIdentifier: identifier,
                requestedPeripheralIdentifier: identifier,
                connectionStatus: .connected,
                peripheralState: .connected
            )
        )
        XCTAssertTrue(
            Device.shouldIgnoreConnectionRequest(
                currentPeripheralIdentifier: identifier,
                requestedPeripheralIdentifier: identifier,
                connectionStatus: .foundConnected,
                peripheralState: .connected
            )
        )
    }

    func testConnectionRequestIsAllowedAfterDisconnectOrForAnotherPeripheral() {
        let currentIdentifier = UUID()

        XCTAssertFalse(
            Device.shouldIgnoreConnectionRequest(
                currentPeripheralIdentifier: currentIdentifier,
                requestedPeripheralIdentifier: currentIdentifier,
                connectionStatus: .disconnected,
                peripheralState: .disconnected
            )
        )
        XCTAssertFalse(
            Device.shouldIgnoreConnectionRequest(
                currentPeripheralIdentifier: currentIdentifier,
                requestedPeripheralIdentifier: UUID(),
                connectionStatus: .connected,
                peripheralState: .connected
            )
        )
    }

    private func noOpCallback(
        onANC: @escaping (NoiseCancellationMode?) -> Void = { _ in },
        onConnect: @escaping (Result<DeviceInfo, Error>) -> Void = { _ in },
        onDisconnect: @escaping (Result<Void, Error>) -> Void = { _ in },
        onError: @escaping (ConnectionError) -> Void = { _ in }
    ) -> Callback {
        Callback(
            onDiscover: { _ in }, onConnect: onConnect, onDisconnect: onDisconnect,
            onUpdateBattery: { _ in }, onUpdateANCMode: onANC,
            onUpdateSpatialAudio: { _ in }, onUpdateEnhancedBass: { _ in },
            onUpdateEQPreset: { _ in }, onUpdateDeviceSettings: { _ in },
            onUpdateRingBuds: { _ in }, onError: onError
        )
    }
}
