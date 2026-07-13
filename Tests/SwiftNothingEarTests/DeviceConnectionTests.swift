@preconcurrency import CoreBluetooth
import XCTest
@testable import SwiftNothingEar

@MainActor
final class DeviceConnectionTests: XCTestCase {

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
}
