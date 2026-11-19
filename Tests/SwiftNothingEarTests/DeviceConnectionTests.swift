@preconcurrency import CoreBluetooth
import XCTest
@testable import SwiftNothingEar

// Lifecycle cases drive Device's session methods directly with synthetic peripheral
// identifiers. `finishSession` stands in for Core Bluetooth's didDisconnect/didFailToConnect,
// and `handleManagerState` for centralManagerDidUpdateState. Packet provenance is noted at
// each byte fixture.
@MainActor
final class DeviceConnectionTests: XCTestCase {

    // The ANC bytes are the existing Ear (2024) capture in NothingEarTests.testANC.
    private let capturedANC = Data([
        0x55, 0x60, 0x01, 0x1E, 0x40, 0x02, 0x00, 0x01,
        0x00, 0x03
    ])

    // MARK: Notifications

    func testNotificationWithoutSessionIsIgnored() {
        var reportedModes: [NoiseCancellationMode?] = []
        let device = Device(noOpCallback(onANC: { reportedModes.append($0) }), initializesBluetooth: false)

        device.processNotification(capturedANC)

        XCTAssertNil(device.ancMode)
        XCTAssertTrue(reportedModes.isEmpty)
    }

    func testNotificationIsIgnoredOnceTeardownIsRequested() {
        var reportedModes: [NoiseCancellationMode?] = []
        let device = Device(noOpCallback(onANC: { reportedModes.append($0) }), initializesBluetooth: false)

        establishEarSession(on: device)
        device.processNotification(capturedANC)
        XCTAssertEqual(reportedModes, [NoiseCancellationMode.active(.low)])

        device.disconnect()
        device.processNotification(capturedANC)
        XCTAssertEqual(reportedModes, [NoiseCancellationMode.active(.low)])
    }

    // MARK: Delayed Initialization

    func testConnectionCleanupCancelsDelayedInitialization() async throws {
        let device = Device(noOpCallback(), initializesBluetooth: false)
        let delayedAction = expectation(description: "stale initialization action")
        delayedAction.isInverted = true

        device.runTasks([{}, { delayedAction.fulfill() }], delay: 0.05)
        device.clearConnectionState()
        await fulfillment(of: [delayedAction], timeout: 1)
    }

    func testCurrentInitializationTasksStillRun() async throws {
        let device = Device(noOpCallback(), initializesBluetooth: false)
        let currentAction = expectation(description: "current initialization action")

        device.beginConnectionSession(for: UUID(), name: nil)
        device.runTasks([{}, { currentAction.fulfill() }], delay: 0.02)
        await fulfillment(of: [currentAction], timeout: 2)
    }

    func testReconnectDropsOldInitializationAndRunsCurrentTasks() async throws {
        let device = Device(noOpCallback(), initializesBluetooth: false)
        let identifier = UUID()
        let oldAction = expectation(description: "old session action")
        oldAction.isInverted = true
        let currentAction = expectation(description: "new session action")

        // Reuse one identifier across two sessions and task schedules.
        device.beginConnectionSession(for: identifier, name: nil)
        device.runTasks([{}, { oldAction.fulfill() }], delay: 0.05)
        device.beginConnectionSession(for: identifier, name: nil)
        device.runTasks([{}, { currentAction.fulfill() }], delay: 0.02)
        await fulfillment(of: [currentAction, oldAction], timeout: 2)
    }

    // MARK: Notification Subscription

    func testHandshakeWaitsForNotificationSubscription() {
        let device = Device(noOpCallback(), initializesBluetooth: false)
        var events: [String] = []

        // These closures stand in for setNotifyValue and the initial handshake.
        device.completeCommunicationSetup(
            enableNotifications: { events.append("subscribe") },
            beginHandshake: { events.append("handshake") }
        )

        XCTAssertEqual(events, ["subscribe"])
    }

    func testSuccessfulSubscriptionStartsHandshakeOnlyOnce() {
        let device = Device(noOpCallback(), initializesBluetooth: false)
        var events: [String] = []

        beginConnectedSession(on: device)
        device.completeCommunicationSetup(
            enableNotifications: { events.append("subscribe") },
            beginHandshake: { events.append("handshake") }
        )
        device.completeNotificationSubscription(isNotifying: true)
        device.completeNotificationSubscription(isNotifying: true)

        XCTAssertEqual(events, ["subscribe", "handshake"])
    }

    func testFailedSubscriptionReportsOnceAndResolvesAttemptOnTeardown() {
        for (isNotifying, hadError) in [(false, false), (true, true)] {
            var errors = 0
            var connectionFailures = 0
            let device = Device(noOpCallback(
                onConnect: { result in
                    if case .failure(ConnectionError.connectionFailed) = result { connectionFailures += 1 }
                },
                onError: { error in
                    if case .connectionFailed = error { errors += 1 }
                }
            ), initializesBluetooth: false)
            var events: [String] = []

            // Notification state is off or reports an error, followed by late success.
            beginConnectedSession(on: device)
            device.completeCommunicationSetup(
                enableNotifications: { events.append("subscribe") },
                beginHandshake: { events.append("handshake") }
            )
            device.completeNotificationSubscription(isNotifying: isNotifying, hadError: hadError)
            device.completeNotificationSubscription(isNotifying: true)

            XCTAssertEqual(events, ["subscribe"])
            XCTAssertEqual(errors, 1)
            XCTAssertEqual(connectionFailures, 0, "The attempt resolves when the link closes")
            XCTAssertFalse(device.isConnected)

            device.finishSession(error: nil)
            XCTAssertEqual(connectionFailures, 1)
            XCTAssertTrue(device.connectionStatus == .disconnected)
        }
    }

    // MARK: Setup Failures

    func testSetupFailureWaitsForTeardownBeforeAllowingSamePeripheralReconnect() {
        var errors = 0
        var connectionFailures = 0
        let device = Device(noOpCallback(
            onConnect: { result in
                if case .failure(ConnectionError.connectionFailed) = result { connectionFailures += 1 }
            },
            onError: { error in
                if case .connectionFailed = error { errors += 1 }
            }
        ), initializesBluetooth: false)
        let identifier = UUID()

        beginConnectedSession(on: device, identifier: identifier)
        device.failInitialSetup(.connectionFailed)
        device.failInitialSetup(.connectionFailed)

        XCTAssertEqual(errors, 1)
        XCTAssertEqual(connectionFailures, 0)
        // Until Core Bluetooth confirms the cancel, a same-peripheral reconnect is ignored,
        // so the cancel's late didDisconnect cannot end a replacement session.
        XCTAssertTrue(shouldIgnoreReconnect(to: identifier, on: device))

        device.finishSession(error: nil)
        XCTAssertEqual(connectionFailures, 1)
        XCTAssertTrue(device.connectionStatus == .disconnected)
        XCTAssertFalse(shouldIgnoreReconnect(to: identifier, on: device))
    }

    func testSetupFailureCallbackCanStartSessionForAnotherPeripheral() {
        let nextIdentifier = UUID()
        var reconnect: (() -> Void)?
        let device = Device(noOpCallback(onError: { _ in reconnect?() }), initializesBluetooth: false)
        reconnect = { [weak device] in
            device?.beginConnectionSession(for: nextIdentifier, name: nil)
        }

        beginConnectedSession(on: device)
        device.completeCommunicationSetup(enableNotifications: {}, beginHandshake: {})
        device.completeNotificationSubscription(isNotifying: false)

        XCTAssertTrue(device.connectionStatus == .connecting)
        XCTAssertFalse(device.isConnected)
        reconnect = nil
        device.clearConnectionState()
    }

    func testInitialSetupSilenceTimesOutOnceFromConnect() async throws {
        for phase in ["connect", "discovery", "subscription"] {
            var timeouts = 0
            var otherErrors = 0
            var handshakes = 0
            var timedOutAttempts = 0
            let timeoutEvent = expectation(description: "\(phase) setup deadline")
            let device = Device(noOpCallback(
                onConnect: { result in
                    if case .failure(ConnectionError.timeout) = result { timedOutAttempts += 1 }
                },
                onError: { error in
                    if case .timeout = error {
                        timeouts += 1
                        timeoutEvent.fulfill()
                    } else {
                        otherErrors += 1
                    }
                }
            ), initializesBluetooth: false, setupTimeoutNanoseconds: 20_000_000)

            // Exercise silence during connect, discovery, and subscription.
            device.beginConnectionSession(for: UUID(), name: nil)
            if phase != "connect" { device.connectionStatus = .connected }
            if phase == "subscription" {
                device.completeCommunicationSetup(
                    enableNotifications: {},
                    beginHandshake: { handshakes += 1 }
                )
            }

            await fulfillment(of: [timeoutEvent], timeout: 2)
            device.completeNotificationSubscription(isNotifying: true)
            device.finishSession(error: nil)

            XCTAssertEqual(timeouts, 1, "phase: \(phase)")
            XCTAssertEqual(otherErrors, 0, "phase: \(phase)")
            XCTAssertEqual(handshakes, 0, "phase: \(phase)")
            XCTAssertEqual(timedOutAttempts, 1, "phase: \(phase)")
            XCTAssertTrue(device.connectionStatus == .disconnected, "phase: \(phase)")
        }
    }

    func testTeardownDeadlineEndsSessionWhenCoreBluetoothStaysSilent() async throws {
        let resolved = expectation(description: "attempt resolved without a terminal callback")
        let device = Device(
            noOpCallback(onConnect: { result in
                if case .failure(ConnectionError.connectionFailed) = result { resolved.fulfill() }
            }),
            initializesBluetooth: false,
            teardownTimeoutNanoseconds: 20_000_000
        )

        beginConnectedSession(on: device)
        device.failInitialSetup(.connectionFailed)
        await fulfillment(of: [resolved], timeout: 2)

        XCTAssertTrue(device.connectionStatus == .disconnected)
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
        ), initializesBluetooth: false, setupTimeoutNanoseconds: 20_000_000)

        establishEarSession(on: device)
        XCTAssertEqual(connections, 1)
        XCTAssertEqual(device.deviceInfo?.model, .ear(.black))
        XCTAssertEqual(device.deviceInfo?.firmwareVersion, "1.0.1.56")

        // connect(to:) uses this session start when replacing a completed session.
        device.beginConnectionSession(for: UUID(), name: nil)
        await fulfillment(of: [timeoutEvent], timeout: 2)
        device.finishSession(error: nil)

        XCTAssertEqual(timeouts, 1)
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
                reconnect = nil
                timeoutEvent.fulfill()
            }
        }), initializesBluetooth: false, setupTimeoutNanoseconds: 20_000_000)
        reconnect = { [weak device] in
            device?.beginConnectionSession(for: UUID(), name: nil)
        }
        device.beginConnectionSession(for: UUID(), name: nil)

        await fulfillment(of: [timeoutEvent], timeout: 2)
        XCTAssertEqual(timeouts, 1)
        XCTAssertTrue(device.connectionStatus == .connecting)
        device.clearConnectionState()
    }

    // MARK: Bluetooth Power

    func testPoweredOffEndsEstablishedSessionOnce() {
        var errors: [ConnectionError] = []
        var disconnects: [Result<Void, Error>] = []
        let device = Device(noOpCallback(
            onDisconnect: { disconnects.append($0) },
            onError: { errors.append($0) }
        ), initializesBluetooth: false)
        establishEarSession(on: device)

        device.handleManagerState(.poweredOff)
        // A late terminal callback finds no session (the real delegate also drops it by identity).
        device.finishSession(error: nil)

        XCTAssertEqual(errors.count, 1)
        if case .bluetooth(.poweredOff) = errors.first {} else { XCTFail("Expected poweredOff error") }
        XCTAssertEqual(disconnects.count, 1)
        if case .success = disconnects.first { XCTFail("Power loss must report a failure") }
        XCTAssertTrue(device.connectionStatus == .disconnected)
    }

    func testTerminalCallbackBeforePoweredOffReportsDisconnectThenError() {
        var events: [String] = []
        let device = Device(noOpCallback(
            onDisconnect: { _ in events.append("disconnect") },
            onError: { error in
                if case .bluetooth(.poweredOff) = error { events.append("poweredOff") }
            }
        ), initializesBluetooth: false)
        establishEarSession(on: device)

        device.finishSession(error: CBError(.connectionTimeout))
        device.handleManagerState(.poweredOff)

        XCTAssertEqual(events, ["disconnect", "poweredOff"])
        XCTAssertTrue(device.connectionStatus == .disconnected)
    }

    func testPoweredOffDuringSetupResolvesAttemptOnce() {
        var connectionFailures = 0
        var poweredOffErrors = 0
        let device = Device(noOpCallback(
            onConnect: { result in
                if case .failure(ConnectionError.bluetooth(.poweredOff)) = result { connectionFailures += 1 }
                if case .success = result { XCTFail("Powered-off setup must not connect") }
            },
            onError: { error in
                if case .bluetooth(.poweredOff) = error { poweredOffErrors += 1 }
            }
        ), initializesBluetooth: false)

        device.beginConnectionSession(for: UUID(), name: nil)
        device.handleManagerState(.poweredOff)
        device.finishSession(error: nil)

        XCTAssertEqual(connectionFailures, 1)
        XCTAssertEqual(poweredOffErrors, 1)
        XCTAssertTrue(device.connectionStatus == .disconnected)
    }

    func testPoweredOffAfterClientDisconnectDuringSetupEndsSession() {
        var connectionFailures = 0
        let device = Device(noOpCallback(
            onConnect: { result in
                if case .failure = result { connectionFailures += 1 }
            }
        ), initializesBluetooth: false)
        let identifier = UUID()

        // The client cancels a pending setup; Bluetooth turns off before Core Bluetooth confirms it.
        beginConnectedSession(on: device, identifier: identifier)
        device.disconnect()
        device.handleManagerState(.poweredOff)

        XCTAssertEqual(connectionFailures, 1)
        XCTAssertTrue(device.connectionStatus == .disconnected)
        XCTAssertFalse(shouldIgnoreReconnect(to: identifier, on: device))
    }

    func testPowerFaultCallbacksCanStartNewSession() {
        for established in [false, true] {
            for reconnectFromError in [false, true] {
                var reconnect: (() -> Void)?
                let runReconnect = {
                    reconnect?()
                    reconnect = nil
                }
                let device = Device(noOpCallback(
                    onConnect: { result in
                        if case .failure = result, !reconnectFromError { runReconnect() }
                    },
                    onDisconnect: { _ in
                        if !reconnectFromError { runReconnect() }
                    },
                    onError: { _ in
                        if reconnectFromError { runReconnect() }
                    }
                ), initializesBluetooth: false)
                if established {
                    establishEarSession(on: device)
                } else {
                    device.beginConnectionSession(for: UUID(), name: nil)
                }
                reconnect = { [weak device] in
                    device?.beginConnectionSession(for: UUID(), name: nil)
                }

                device.handleManagerState(.poweredOff)

                let order = "established=\(established), reconnectFromError=\(reconnectFromError)"
                XCTAssertNil(reconnect, order)
                XCTAssertTrue(device.connectionStatus == .connecting, order)
                device.clearConnectionState()
            }
        }
    }

    // MARK: Client Disconnect

    func testRepeatedClientDisconnectReportsDisconnectOnce() {
        var disconnects = 0
        let device = Device(noOpCallback(onDisconnect: { _ in disconnects += 1 }), initializesBluetooth: false)
        let identifier = UUID()

        establishEarSession(on: device, identifier: identifier)
        device.disconnect()
        device.disconnect()
        XCTAssertFalse(device.isConnected)
        XCTAssertTrue(shouldIgnoreReconnect(to: identifier, on: device))

        device.finishSession(error: nil)
        device.finishSession(error: nil)

        XCTAssertEqual(disconnects, 1)
        XCTAssertTrue(device.connectionStatus == .disconnected)
        XCTAssertFalse(shouldIgnoreReconnect(to: identifier, on: device))
    }

    func testClientDisconnectDuringSetupResolvesAttempt() {
        var connectionFailures = 0
        var disconnects = 0
        let device = Device(noOpCallback(
            onConnect: { result in
                if case .failure = result { connectionFailures += 1 }
            },
            onDisconnect: { _ in disconnects += 1 }
        ), initializesBluetooth: false)

        device.beginConnectionSession(for: UUID(), name: nil)
        device.disconnect()
        device.finishSession(error: nil)

        XCTAssertEqual(connectionFailures, 1)
        XCTAssertEqual(disconnects, 0)
        XCTAssertTrue(device.connectionStatus == .disconnected)
    }

    // MARK: Duplicate Requests

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

    // MARK: Helpers

    /// Mirrors connect(to:) followed by didConnect, without a Core Bluetooth peripheral.
    private func beginConnectedSession(on device: Device, identifier: UUID = UUID()) {
        device.beginConnectionSession(for: identifier, name: nil)
        device.connectionStatus = .connected
    }

    /// Uses the session's status as connect(to:) would for the same peripheral.
    private func shouldIgnoreReconnect(to identifier: UUID, on device: Device) -> Bool {
        let sessionIdentifier = device.connectionStatus == .disconnected ? nil : identifier
        return Device.shouldIgnoreConnectionRequest(
            currentPeripheralIdentifier: sessionIdentifier,
            requestedPeripheralIdentifier: identifier,
            connectionStatus: device.connectionStatus,
            peripheralState: .connected
        )
    }

    private func establishEarSession(on device: Device, identifier: UUID = UUID()) {
        device.beginConnectionSession(for: identifier, name: "Nothing Ear")
        device.connectionStatus = .connected

        // Captured Ear (2024) identity from NothingEarTests.testDeviceConfigUsesBluetoothAddressWhenSerialIsEmpty.
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
        // Synthetic firmware envelope with the capture's version; this is not a captured packet.
        let syntheticFirmware = [UInt8(0x55), 0x60, 0x01, 0x42, 0x40, 0x08, 0x00, 0x02]
            + Array("1.0.1.56".utf8)
        device.processResponse(Data(capturedIdentity))
        device.processResponse(Data(syntheticFirmware))
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
