@preconcurrency import CoreBluetooth
import XCTest
@testable import SwiftNothingEar

// Lifecycle cases use synthetic peripheral identifiers, callback order, and
// closures against Device's production seams. Packet provenance is noted at
// each byte fixture.
@MainActor
final class DeviceConnectionTests: XCTestCase {

    func testNotificationFromInactiveSessionDoesNotUpdateANC() {
        var reportedModes: [NoiseCancellationMode?] = []
        let device = Device(noOpCallback(onANC: { reportedModes.append($0) }), initializesBluetooth: false)

        // A queued notification arrives with no active session. A new Device starts at generation 0.
        // The ANC bytes are the existing Ear (2024) capture in NothingEarTests.testANC.
        let capturedANC = Data([
            0x55, 0x60, 0x01, 0x1E, 0x40, 0x02, 0x00, 0x01,
            0x00, 0x03
        ])
        device.processNotification(capturedANC, from: UUID(), generation: 0)

        XCTAssertNil(device.ancMode)
        XCTAssertTrue(reportedModes.isEmpty)
    }

    func testConnectionCleanupCancelsDelayedInitialization() async throws {
        let device = Device(noOpCallback(), initializesBluetooth: false)
        let delayedAction = expectation(description: "stale initialization action")
        delayedAction.isInverted = true

        // Schedule a delayed request, then run the cleanup used by disconnect callbacks.
        device.runTasks([{}, { delayedAction.fulfill() }], delay: 0.05)
        device.clearConnectionState()
        await fulfillment(of: [delayedAction], timeout: 1)
    }

    func testCurrentInitializationTasksStillRun() async throws {
        let device = Device(noOpCallback(), initializesBluetooth: false)
        let currentAction = expectation(description: "current initialization action")

        // Exercise the active generation of the initialization scheduler.
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

        // Reuse one identifier across two sessions and task schedules.
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

        // A queued callback retains the old generation while the same identifier starts a new session.
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

            // Notification state is off or reports an error, followed by late success.
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

        // onError reenters Device while a failed subscription is being retired.
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

            // Exercise silence during connect, discovery, and subscription.
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

        // connect(to:) uses this session start when replacing a completed session.
        device.beginConnectionSession(for: UUID())
        await fulfillment(of: [timeoutEvent], timeout: 2)

        XCTAssertEqual(timeouts, 1)
        XCTAssertTrue(device.connectionStatus == .disconnected)
    }

    func testRapidPowerRecoveryProcessesCurrentPoweredOnState() {
        let device = Device(noOpCallback(), initializesBluetooth: false)
        let generation = device.beginConnectionSession(for: UUID())
        var discoveryChecks = 0

        // poweredOff and poweredOn were delivered before queued completions ran. The manager
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

        // The queued poweredOn callback is stale because the manager is now off.
        device.processCentralStateUpdate(
            observedState: .poweredOn,
            generation: generation,
            currentState: { .poweredOff },
            onPoweredOn: { discoveryChecks += 1 }
        )

        XCTAssertEqual(discoveryChecks, 0)
    }

    func testPoweredOffBeforeQueuedDisconnectCleanupReportsDisconnect() {
        var connections = 0
        var disconnects = 0
        var errors = 0
        var poweredOffErrors = 0
        let device = Device(noOpCallback(
            onConnect: { result in
                if case .success = result { connections += 1 }
            },
            onDisconnect: { _ in disconnects += 1 },
            onError: { error in
                errors += 1
                if case .bluetooth(.poweredOff) = error { poweredOffErrors += 1 }
            }
        ), initializesBluetooth: false)
        let identifier = UUID()
        let initialGeneration = establishEarSession(on: device, identifier: identifier)
        XCTAssertEqual(connections, 1)
        XCTAssertTrue(device.connectionStatus == .connected)

        // Terminal receipt has queued cleanup. The poweredOff completion runs first.
        let terminalGeneration = device.recordTerminalReceipt()
        device.processCentralStateUpdate(
            observedState: .poweredOff,
            generation: terminalGeneration,
            currentState: { .poweredOff },
            onPoweredOn: { XCTFail("Powered-off state must not trigger discovery") }
        )
        device.completeDisconnection(
            from: identifier,
            generation: terminalGeneration,
            name: "synthetic",
            error: nil,
            managerState: .poweredOff
        )
        device.processCentralStateUpdate(
            observedState: .poweredOff,
            generation: initialGeneration,
            currentState: { .poweredOff },
            onPoweredOn: { XCTFail("Powered-off state must not trigger discovery") }
        )

        XCTAssertEqual(errors, 1)
        XCTAssertEqual(poweredOffErrors, 1)
        XCTAssertEqual(disconnects, 1)
        XCTAssertTrue(device.connectionStatus == .disconnected)
    }

    func testPoweredOffBeforeTerminalReceiptReportsDisconnectOnce() {
        var errors = 0
        var disconnects = 0
        let device = Device(noOpCallback(
            onDisconnect: { _ in disconnects += 1 },
            onError: { error in
                if case .bluetooth(.poweredOff) = error { errors += 1 }
            }
        ), initializesBluetooth: false)
        let identifier = UUID()
        let initialGeneration = establishEarSession(on: device, identifier: identifier)

        device.processCentralStateUpdate(
            observedState: .poweredOff,
            generation: initialGeneration,
            currentState: { .poweredOff },
            onPoweredOn: { XCTFail("Powered-off state must not trigger discovery") }
        )
        let lateTerminalGeneration = device.recordTerminalReceipt()
        device.completeDisconnection(
            from: identifier, generation: lateTerminalGeneration,
            name: "synthetic", error: nil, managerState: .poweredOff
        )
        device.processCentralStateUpdate(
            observedState: .poweredOff,
            generation: initialGeneration,
            currentState: { .poweredOff },
            onPoweredOn: { XCTFail("Powered-off state must not trigger discovery") }
        )

        XCTAssertEqual(errors, 1)
        XCTAssertEqual(disconnects, 1)
        XCTAssertTrue(device.connectionStatus == .disconnected)
    }

    func testTerminalCleanupBeforePoweredOffStateReportsErrorAndDisconnectOnce() {
        var errors = 0
        var disconnects = 0
        let device = Device(noOpCallback(
            onDisconnect: { _ in disconnects += 1 },
            onError: { error in
                if case .bluetooth(.poweredOff) = error { errors += 1 }
            }
        ), initializesBluetooth: false)
        let identifier = UUID()
        establishEarSession(on: device, identifier: identifier)
        let terminalGeneration = device.recordTerminalReceipt()

        device.completeDisconnection(
            from: identifier, generation: terminalGeneration,
            name: "synthetic", error: nil, managerState: .poweredOff
        )
        device.processCentralStateUpdate(
            observedState: .poweredOff,
            generation: terminalGeneration,
            currentState: { .poweredOff },
            onPoweredOn: { XCTFail("Powered-off state must not trigger discovery") }
        )
        // A second manager callback can be captured after terminal cleanup advances the generation.
        device.processCentralStateUpdate(
            observedState: .poweredOff,
            generation: terminalGeneration &+ 1,
            currentState: { .poweredOff },
            onPoweredOn: { XCTFail("Powered-off state must not trigger discovery") }
        )
        device.completeDisconnection(
            from: identifier, generation: terminalGeneration,
            name: "synthetic", error: nil, managerState: .poweredOff
        )

        XCTAssertEqual(errors, 1)
        XCTAssertEqual(disconnects, 1)
        XCTAssertTrue(device.connectionStatus == .disconnected)
    }

    func testPowerFaultCallbacksCanStartNewSessionWithoutOldCleanupClearingIt() {
        for terminalCleanupFirst in [false, true] {
            for reconnectFromError in [false, true] {
                var errors = 0
                var disconnects = 0
                var reconnect: (() -> Void)?
                let device = Device(noOpCallback(
                    onDisconnect: { _ in
                        disconnects += 1
                        if !reconnectFromError { reconnect?() }
                    },
                    onError: { error in
                        if case .bluetooth(.poweredOff) = error {
                            errors += 1
                            if reconnectFromError { reconnect?() }
                        }
                    }
                ), initializesBluetooth: false)
                let oldIdentifier = UUID()
                establishEarSession(on: device, identifier: oldIdentifier)
                reconnect = { [weak device] in
                    _ = device?.beginConnectionSession(for: UUID())
                }
                let terminalGeneration = device.recordTerminalReceipt()
                let applyPowerState = {
                    device.processCentralStateUpdate(
                        observedState: .poweredOff,
                        generation: terminalGeneration,
                        currentState: { .poweredOff },
                        onPoweredOn: { XCTFail("Powered-off state must not trigger discovery") }
                    )
                }
                let finishTerminal = {
                    device.completeDisconnection(
                        from: oldIdentifier, generation: terminalGeneration,
                        name: "synthetic", error: nil, managerState: .poweredOff
                    )
                }
                if terminalCleanupFirst {
                    finishTerminal()
                    applyPowerState()
                } else {
                    applyPowerState()
                    finishTerminal()
                }
                applyPowerState()
                finishTerminal()

                let order = "cleanupFirst=\(terminalCleanupFirst), reconnectFromError=\(reconnectFromError)"
                XCTAssertEqual(errors, 1, order)
                XCTAssertEqual(disconnects, 1, order)
                XCTAssertTrue(device.connectionStatus == .connecting, order)
                device.clearConnectionState()
                reconnect = nil
            }
        }
    }

    func testPoweredOffDuringFailedConnectReceiptReportsErrorAndTerminalFailureOnce() {
        var connectionFailures = 0
        var poweredOffErrors = 0
        let device = Device(noOpCallback(
            onConnect: { result in
                if case .failure = result { connectionFailures += 1 }
            },
            onError: { error in
                if case .bluetooth(.poweredOff) = error { poweredOffErrors += 1 }
            }
        ), initializesBluetooth: false)
        let identifier = UUID()
        device.beginConnectionSession(for: identifier)

        // didFailToConnect records receipt before its MainActor completion runs.
        let terminalGeneration = device.recordTerminalReceipt()
        device.processCentralStateUpdate(
            observedState: .poweredOff,
            generation: terminalGeneration,
            currentState: { .poweredOff },
            onPoweredOn: { XCTFail("Powered-off state must not trigger discovery") }
        )
        device.completeFailedConnection(
            from: identifier, generation: terminalGeneration,
            name: "synthetic", error: nil, managerState: .poweredOff
        )
        device.completeFailedConnection(
            from: identifier, generation: terminalGeneration,
            name: "synthetic", error: nil, managerState: .poweredOff
        )
        device.processCentralStateUpdate(
            observedState: .poweredOff,
            generation: terminalGeneration &+ 1,
            currentState: { .poweredOff },
            onPoweredOn: { XCTFail("Powered-off state must not trigger discovery") }
        )

        XCTAssertEqual(connectionFailures, 1)
        XCTAssertEqual(poweredOffErrors, 1)
        XCTAssertTrue(device.connectionStatus == .disconnected)
    }

    func testPoweredOffCallbackCapturedBeforeFailedConnectReceiptReportsErrorAndTerminalFailureOnce() {
        var connectionFailures = 0
        var poweredOffErrors = 0
        let device = Device(noOpCallback(
            onConnect: { result in
                if case .failure = result { connectionFailures += 1 }
            },
            onError: { error in
                if case .bluetooth(.poweredOff) = error { poweredOffErrors += 1 }
            }
        ), initializesBluetooth: false)
        let identifier = UUID()
        let stateGeneration = device.beginConnectionSession(for: identifier)

        // The queued manager callback holds the old generation when didFailToConnect arrives.
        let terminalGeneration = device.recordTerminalReceipt()
        device.processCentralStateUpdate(
            observedState: .poweredOff,
            generation: stateGeneration,
            currentState: { .poweredOff },
            onPoweredOn: { XCTFail("Powered-off state must not trigger discovery") }
        )
        device.completeFailedConnection(
            from: identifier, generation: terminalGeneration,
            name: "synthetic", error: nil, managerState: .poweredOff
        )
        device.completeFailedConnection(
            from: identifier, generation: terminalGeneration,
            name: "synthetic", error: nil, managerState: .poweredOff
        )

        XCTAssertEqual(connectionFailures, 1)
        XCTAssertEqual(poweredOffErrors, 1)
        XCTAssertTrue(device.connectionStatus == .disconnected)
    }

    func testPoweredOffBeforeFailedConnectReceiptReportsErrorAndTerminalFailureOnce() {
        var connectionFailures = 0
        var errors = 0
        var poweredOffErrors = 0
        let device = Device(noOpCallback(
            onConnect: { result in
                if case .failure = result { connectionFailures += 1 }
                if case .success = result { XCTFail("Powered-off setup must not connect") }
            },
            onError: { error in
                errors += 1
                if case .bluetooth(.poweredOff) = error { poweredOffErrors += 1 }
            }
        ), initializesBluetooth: false)
        let identifier = UUID()
        let stateGeneration = device.beginConnectionSession(for: identifier)

        // Manager state reaches Device before the failed-connect delegate receipt.
        device.processCentralStateUpdate(
            observedState: .poweredOff,
            generation: stateGeneration,
            currentState: { .poweredOff },
            onPoweredOn: { XCTFail("Powered-off state must not trigger discovery") }
        )
        device.processCentralStateUpdate(
            observedState: .poweredOff,
            generation: stateGeneration,
            currentState: { .poweredOff },
            onPoweredOn: { XCTFail("Powered-off state must not trigger discovery") }
        )
        let lateTerminalGeneration = device.recordTerminalReceipt()
        device.completeFailedConnection(
            from: identifier, generation: lateTerminalGeneration,
            name: "synthetic", error: nil, managerState: .poweredOff
        )
        device.completeFailedConnection(
            from: identifier, generation: lateTerminalGeneration,
            name: "synthetic", error: nil, managerState: .poweredOff
        )

        XCTAssertEqual(connectionFailures, 1)
        XCTAssertEqual(errors, 1)
        XCTAssertEqual(poweredOffErrors, 1)
        XCTAssertTrue(device.connectionStatus == .disconnected)
    }

    func testFailedConnectPowerFaultCallbacksCanStartNewSession() {
        for stateFirst in [false, true] {
            for reconnectFromError in [false, true] {
                var connectionFailures = 0
                var poweredOffErrors = 0
                var reconnect: (() -> Void)?
                let device = Device(noOpCallback(
                    onConnect: { result in
                        if case .failure = result {
                            connectionFailures += 1
                            if !reconnectFromError { reconnect?() }
                        }
                    },
                    onError: { error in
                        if case .bluetooth(.poweredOff) = error {
                            poweredOffErrors += 1
                            if reconnectFromError { reconnect?() }
                        }
                    }
                ), initializesBluetooth: false)
                let oldIdentifier = UUID()
                let stateGeneration = device.beginConnectionSession(for: oldIdentifier)
                reconnect = { [weak device] in
                    _ = device?.beginConnectionSession(for: UUID())
                }
                let terminalGeneration = stateFirst ? stateGeneration : device.recordTerminalReceipt()
                device.processCentralStateUpdate(
                    observedState: .poweredOff,
                    generation: terminalGeneration,
                    currentState: { .poweredOff },
                    onPoweredOn: { XCTFail("Powered-off state must not trigger discovery") }
                )
                // After state-first cleanup, the real delegate's peripheral identity guard drops receipt.
                device.completeFailedConnection(
                    from: oldIdentifier, generation: terminalGeneration,
                    name: "synthetic", error: nil, managerState: .poweredOff
                )
                device.completeFailedConnection(
                    from: oldIdentifier, generation: terminalGeneration,
                    name: "synthetic", error: nil, managerState: .poweredOff
                )
                device.processCentralStateUpdate(
                    observedState: .poweredOff,
                    generation: terminalGeneration,
                    currentState: { .poweredOff },
                    onPoweredOn: { XCTFail("Powered-off state must not trigger discovery") }
                )

                let order = "stateFirst=\(stateFirst), reconnectFromError=\(reconnectFromError)"
                XCTAssertEqual(connectionFailures, 1, order)
                XCTAssertEqual(poweredOffErrors, 1, order)
                XCTAssertTrue(device.connectionStatus == .connecting, order)
                device.clearConnectionState()
                reconnect = nil
            }
        }
    }

    func testSetupFailureReportsOnceAndEndsSession() async throws {
        var errors = 0
        var connectionFailures = 0
        let duplicateError = expectation(description: "duplicate setup error")
        duplicateError.isInverted = true
        let device = Device(noOpCallback(
            onConnect: { result in
                if case .failure = result { connectionFailures += 1 }
            },
            onError: { error in
                if case .connectionFailed = error {
                    errors += 1
                    if errors > 1 { duplicateError.fulfill() }
                }
            }
        ), initializesBluetooth: false)
        device.setupTimeoutNanoseconds = 20_000_000

        // Service, characteristic, subscription, and timeout failures share this path.
        device.beginConnectionSession(for: UUID())
        device.markSessionConnected()
        device.failInitialSetup(.connectionFailed)
        device.failInitialSetup(.connectionFailed)
        await fulfillment(of: [duplicateError], timeout: 0.2)

        XCTAssertEqual(errors, 1)
        XCTAssertEqual(connectionFailures, 0)
        XCTAssertTrue(device.connectionStatus == .disconnected)
    }

    func testQueuedDisconnectCannotClearNewSession() {
        var disconnects = 0
        let device = Device(noOpCallback(onDisconnect: { _ in disconnects += 1 }), initializesBluetooth: false)
        let identifier = UUID()

        // An old MainActor completion arrives after the same identifier starts a new session.
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

            // Exercise terminal receipt, client cancellation, and queued completion in both orders.
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

            // Exercise didFailToConnect receipt and queued completion in both orders.
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

    @discardableResult
    private func establishEarSession(on device: Device, identifier: UUID) -> UInt64 {
        let generation = device.beginConnectionSession(for: identifier)
        device.markSessionConnected()

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
        device.processResponse(Data(capturedIdentity), deviceName: "Nothing Ear")
        device.processResponse(Data(syntheticFirmware))
        return generation
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
