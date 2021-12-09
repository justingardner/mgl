//
//  mglLocalServerTests.swift
//  mglMetalTests
//
//  Created by Benjamin Heasly on 12/9/21.
//  Copyright © 2021 GRU. All rights reserved.
//

import XCTest
@testable import mglMetal

class mglLocalSocketTests: XCTestCase {

    // Server and client are created for each test method.
    static let socketPath = "test"
    let server = mglLocalServer(pathToBind: socketPath)
    let client = mglLocalClient(pathToConnect: socketPath)

    override func setUpWithError() throws {
        // Sanity check server status before connection accepted.
        XCTAssertGreaterThanOrEqual(server.boundSocketDescriptor, 0)
        XCTAssertFalse(server.clientIsAccepted())
        XCTAssertFalse(server.dataWaiting())

        // Sanity check client should start out in connected state (but not yet accepted).
        XCTAssertGreaterThanOrEqual(client.socketDescriptor, 0)

        // Let the server accept the client's connection.
        server.waitForClientToConnect()
        XCTAssertTrue(server.clientIsAccepted())
    }

    override func tearDownWithError() throws {
        client.disconnect()
        XCTAssertLessThan(client.socketDescriptor, 0)

        server.disconnect()
        XCTAssertLessThan(server.acceptedSocketDescriptor, 0)
    }

    func testClientSendToServer() throws {
        XCTAssertFalse(server.dataWaiting())

        let byteCount = 512
        let bytesSentFromClient = (0 ..< byteCount).map { _ in UInt8.random(in: 0...UInt8.max) }
        let clientBytesSent = bytesSentFromClient.withUnsafeBufferPointer {
            client.sendData(buffer: $0.baseAddress!, byteCount: byteCount)
        }
        XCTAssertEqual(clientBytesSent, byteCount)
        XCTAssertTrue(server.dataWaiting())

        var serverBuffer = [UInt8](repeating: 0, count: byteCount)
        let serverBytesRead = serverBuffer.withUnsafeMutableBufferPointer {
            server.readData(buffer: $0.baseAddress!, expectedByteCount: 512)
        }
        XCTAssertEqual(serverBytesRead, byteCount)
        XCTAssertTrue(bytesSentFromClient.elementsEqual(serverBuffer))
        XCTAssertFalse(server.dataWaiting())
    }

    func testServerSendToClient() throws {
        XCTAssertFalse(client.dataWaiting())

        let byteCount = 512
        let bytesSentFromServer = (0 ..< byteCount).map { _ in UInt8.random(in: 0...UInt8.max) }
        let serverBytesSent = bytesSentFromServer.withUnsafeBufferPointer {
            server.sendData(buffer: $0.baseAddress!, byteCount: byteCount)
        }
        XCTAssertEqual(serverBytesSent, byteCount)
        XCTAssertTrue(client.dataWaiting())

        var clientBuffer = [UInt8](repeating: 0, count: byteCount)
        let clientBytesRead = clientBuffer.withUnsafeMutableBufferPointer {
            client.readData(buffer: $0.baseAddress!, expectedByteCount: 512)
        }
        XCTAssertEqual(clientBytesRead, byteCount)
        XCTAssertTrue(bytesSentFromServer.elementsEqual(clientBuffer))
        XCTAssertFalse(client.dataWaiting())
    }

}
