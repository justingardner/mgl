//
//  mglMetalTests.swift
//  mglMetalTests
//
//  Created by justin gardner on 12/28/19.
//  Copyright © 2019 GRU. All rights reserved.
//

import XCTest
import MetalKit
@testable import mglMetal

// Helpful post on setting up this kind of test: http://fullytyped.com/2019/01/07/on-screen-unit-tests/
class mglMetalTests: XCTestCase {
    private let testAddress = "mglMetalTests.socket"

    private var server: mglLocalServer!
    private var client: mglLocalClient!

    private var viewController: ViewController!
    private var view: MTKView!
    private var commandInterface: mglCommandInterface!

    private var offscreenTexture: MTLTexture!

    override func setUp() {
        // XCTestCase automatically launches our whole app and runs these tests in the same process.
        // This means we can drill down and find our custom view controller, configure it, and control it.
        let window = NSApplication.shared.mainWindow!
        viewController = window.contentViewController as? ViewController

        // Tests will frames one at a time instead of using a scheduled frame rate.
        view = viewController.view as? MTKView
        view.isPaused = true
        view.enableSetNeedsDisplay = false

        // Create a client-server pair we can use to test-drive the app.
        server = mglLocalServer(logger: viewController.logger, pathToBind: testAddress)
        client = mglLocalClient(logger: viewController.logger, pathToConnect: testAddress)

        // Use a private server and connection address during testing instead of the default.
        commandInterface = mglCommandInterface(logger: viewController.logger, server: server)
        viewController.setUpRenderer(view: view, commandInterface: commandInterface)

        // Trigger one frame to allow the server to accept the test client's connection.
        view.draw()
        let accepted = server.clientIsAccepted()
        XCTAssertTrue(accepted)

        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba32Float,
            width: 640,
            height: 480,
            mipmapped: false
        )
        textureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        offscreenTexture = view.device!.makeTexture(descriptor: textureDescriptor)
    }

    override func tearDown() {
        client.disconnect()
        server.disconnect()
    }

    private func drawNextFrame(sleepSecs: TimeInterval = TimeInterval.zero) {
        view.draw()
        if (sleepSecs > TimeInterval.zero) {
            Thread.sleep(forTimeInterval: sleepSecs)
        }
    }

    func assertTimestampReply(atLeast: Double = 0.0) {
        var timestamp = 0.0
        let bytesRead = client.readData(buffer: &timestamp, expectedByteCount: 8)
        XCTAssertEqual(bytesRead, 8)
        XCTAssertGreaterThanOrEqual(timestamp, atLeast)
    }

    func assertCommandResultsReply(
        commandCode: mglCommandCode,
        status: UInt32 = 1,
        processedAtLeast: Double = 0.0,
        timestampAtLeast: Double = 0.0
    ) {
        assertCommandCodeReply(expected: commandCode)
        assertUInt32Reply(expected: status)
        assertTimestampReply(atLeast: processedAtLeast)
        assertTimestampReply(atLeast: timestampAtLeast)
        assertTimestampReply(atLeast: timestampAtLeast)
        assertTimestampReply(atLeast: timestampAtLeast)
        assertTimestampReply(atLeast: timestampAtLeast)
        assertTimestampReply(atLeast: timestampAtLeast)
        assertTimestampReply(atLeast: timestampAtLeast)
    }

    func assertCommandCodeReply(expected: mglCommandCode) {
        var commandCode = mglUnknownCommand
        let bytesRead = client.readData(buffer: &commandCode, expectedByteCount: 2)
        XCTAssertEqual(bytesRead, 2)
        XCTAssertEqual(commandCode, expected)
    }

    func assertUInt32Reply(expected: UInt32) {
        var value = UInt32(0)
        let bytesRead = client.readData(buffer: &value, expectedByteCount: 4)
        XCTAssertEqual(bytesRead, 4)
        XCTAssertEqual(value, expected)
    }

    private func sendCommandCode(commandCode: mglCommandCode) {
        var codeValue = commandCode.rawValue
        let bytesSent = client.sendData(buffer: &codeValue, byteCount: 2)
        XCTAssertEqual(bytesSent, 2)
    }

    private func sendColor(r: Float32, g: Float32, b: Float32) {
        let color: [Float32] = [r, g, b]
        let bytesSent = color.withUnsafeBufferPointer {
            client.sendData(buffer: $0.baseAddress!, byteCount: 12)
        }
        XCTAssertEqual(bytesSent, 12)
    }

    private func sendUInt32(value: UInt32) {
        var value2 = value
        let bytesSent = client.sendData(buffer: &value2, byteCount: 4)
        XCTAssertEqual(bytesSent, 4)
    }

    private func sendXYZRGBVertex(x: Float32, y: Float32, z: Float32, r: Float32, g: Float32, b: Float32) {
        let vertex: [Float32] = [x, y, z, r, g, b]
        let bytesSent = vertex.withUnsafeBufferPointer {
            client.sendData(buffer: $0.baseAddress!, byteCount: 24)
        }
        XCTAssertEqual(bytesSent, 24)
    }

    func assertViewClearColor(r: Double, g: Double, b: Double) {
        XCTAssertEqual(view.clearColor.red, r)
        XCTAssertEqual(view.clearColor.green, g)
        XCTAssertEqual(view.clearColor.blue, b)
        XCTAssertEqual(view.clearColor.alpha, 1.0)
    }

    func testClearColorViaClientBytes() {
        // Send a clear command with the color green.
        sendCommandCode(commandCode: mglSetClearColor)
        sendColor(r: 0.0, g: 1.0, b: 0.0)

        // Send a flush command to present the new clear color.
        sendCommandCode(commandCode: mglFlush)

        // Consume the clear and flush commands and present a frame for visual inspection.
        drawNextFrame(sleepSecs: 0.5)

        // Processing the clear command should have set the view's clear color for future frames.
        assertViewClearColor(r: 0.0, g: 1.0, b: 0.0)

        // The server should send an ack timestamp for each command.
        // These look out of order here in this test because we're calling drawNextFrame() synchronously.
        // We don't want to enter the drawing tight loop until after sending the flush.
        // A client in another process should expect see interleaved ack, results, ack, results...
        assertTimestampReply()
        assertTimestampReply()

        // The server should send a result record for the clear color command.
        assertCommandResultsReply(commandCode: mglSetClearColor)
        XCTAssertFalse(client.dataWaiting())

        // The last result record, for flush, waits until the start of the next frame.
        drawNextFrame()
        assertCommandResultsReply(commandCode: mglFlush)
        XCTAssertFalse(client.dataWaiting())
    }

    private func assertSuccess(command: mglCommand, timestampAtLeast: Double = 0.0) {
        XCTAssertTrue(command.results.success)
        XCTAssertGreaterThanOrEqual(command.results.ackTime, timestampAtLeast)
        XCTAssertGreaterThanOrEqual(command.results.processedTime, timestampAtLeast)
        XCTAssertGreaterThanOrEqual(command.results.vertexStart, timestampAtLeast)
        XCTAssertGreaterThanOrEqual(command.results.vertexEnd, timestampAtLeast)
        XCTAssertGreaterThanOrEqual(command.results.fragmentStart, timestampAtLeast)
        XCTAssertGreaterThanOrEqual(command.results.fragmentEnd, timestampAtLeast)
        XCTAssertGreaterThanOrEqual(command.results.drawableAcquired, timestampAtLeast)
        XCTAssertGreaterThanOrEqual(command.results.drawablePresented, timestampAtLeast)
    }

    private struct RGBAFloat32Pixel : Equatable {
        let r: Float32
        let g: Float32
        let b: Float32
        let a: Float32
    }

    private func assertAllOffscreenPixels(expectedPixel: RGBAFloat32Pixel) {
        let region = MTLRegionMake2D(0, 0, offscreenTexture.width, offscreenTexture.height)
        let bytesPerRow = offscreenTexture.width * MemoryLayout<RGBAFloat32Pixel>.stride
        let pixelPointer = UnsafeMutablePointer<RGBAFloat32Pixel>.allocate(capacity: offscreenTexture.width * offscreenTexture.height)
        offscreenTexture.getBytes(pixelPointer, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        let pixelBuffer = UnsafeBufferPointer(start: pixelPointer, count: offscreenTexture.width * offscreenTexture.height)
        let allPixelsAsExpected = pixelBuffer.allSatisfy { pixel in
            pixel == expectedPixel
        }
        XCTAssertTrue(allPixelsAsExpected)
    }

    func testClearColorInMemory() {
        // Create a texture for offscreen rendering.
        let createTexture = mglCreateTextureCommand(texture: offscreenTexture)
        commandInterface.addLast(command: createTexture)
        drawNextFrame()
        assertSuccess(command: createTexture)
        XCTAssertGreaterThan(createTexture.textureNumber, 0)

        // Asssign the new texture as the offscreen rendering target.
        let setRenderTarget = mglSetRenderTargetCommand(textureNumber: createTexture.textureNumber)
        commandInterface.addLast(command: setRenderTarget)
        drawNextFrame()
        assertSuccess(command: setRenderTarget)

        // Enqueue clear and flush commands.
        let clear = mglSetClearColorCommand(red: 0.0, green: 0.0, blue: 1.0)
        commandInterface.addLast(command: clear)
        let flush = mglFlushCommand()
        commandInterface.addLast(command: flush)

        // Processing the clear command should change the view clear color.
        drawNextFrame()
        assertSuccess(command: clear)
        assertViewClearColor(r: 0.0, g: 0.0, b: 1.0)

        // Processing the flush command should draw the clear color to all pixels.
        let expectedPixel = RGBAFloat32Pixel(r: 0.0, g: 0.0, b: 1.0, a: 1.0)
        assertAllOffscreenPixels(expectedPixel: expectedPixel)

        // The the processed time for the flush command waits until the start of the next frame.
        drawNextFrame()
        assertSuccess(command: flush)
    }

    func testCommandBatchViaClientBytes() {
        // The command interface should start out in its "none" state, with no batch happening.
        XCTAssertEqual(commandInterface.getBatchState(), BatchState.none)

        // Put the command interface into batch "building" state.
        sendCommandCode(commandCode: mglStartBatch)
        drawNextFrame()
        assertTimestampReply()
        XCTAssertEqual(commandInterface.getBatchState(), BatchState.building)

        // Send several pairs of set-clear-color and flush commands.
        // Each one should get back an ack time and a placeholder results record.
        // Red
        sendCommandCode(commandCode: mglSetClearColor)
        sendColor(r: 1.0, g: 0.0, b: 0.0)
        drawNextFrame()
        assertTimestampReply()
        assertCommandResultsReply(commandCode: mglSetClearColor)

        sendCommandCode(commandCode: mglFlush)
        drawNextFrame()
        assertTimestampReply()
        assertCommandResultsReply(commandCode: mglFlush)

        // Green
        sendCommandCode(commandCode: mglSetClearColor)
        sendColor(r: 0.0, g: 1.0, b: 0.0)
        drawNextFrame()
        assertTimestampReply()
        assertCommandResultsReply(commandCode: mglSetClearColor)

        sendCommandCode(commandCode: mglFlush)
        drawNextFrame()
        assertTimestampReply()
        assertCommandResultsReply(commandCode: mglFlush)

        // Blue
        sendCommandCode(commandCode: mglSetClearColor)
        sendColor(r: 0.0, g: 0.0, b: 1.0)
        drawNextFrame()
        assertTimestampReply()
        assertCommandResultsReply(commandCode: mglSetClearColor)

        sendCommandCode(commandCode: mglFlush)
        drawNextFrame()
        assertTimestampReply()
        assertCommandResultsReply(commandCode: mglFlush)

        // These commands should all be enqueued as todo, and not yet processed or reported.
        XCTAssertFalse(client.dataWaiting())

        // Since the commands aren't processed yet, the view's clear color should be default gray.
        assertViewClearColor(r: 0.5, g: 0.5, b: 0.5)

        // Put the command interface into batch "processing" state.
        sendCommandCode(commandCode: mglProcessBatch)
        drawNextFrame(sleepSecs: 0.5)
        assertTimestampReply()
        XCTAssertEqual(commandInterface.getBatchState(), BatchState.processing)

        // We should now see the clear colors in order: red, green, blue.
        // The socket should remain quiet during processing.
        // Red
        assertViewClearColor(r: 1.0, g: 0.0, b: 0.0)
        XCTAssertFalse(client.dataWaiting())

        // Green
        drawNextFrame(sleepSecs: 0.5)
        assertViewClearColor(r: 0.0, g: 1.0, b: 0.0)
        XCTAssertFalse(client.dataWaiting())

        // Blue
        drawNextFrame(sleepSecs: 0.5)
        assertViewClearColor(r: 0.0, g: 0.0, b: 1.0)
        XCTAssertFalse(client.dataWaiting())

        // Wait for the signal that tells us all commands are processed.
        // This also tells us how many result records are pending, in this case 6.
        drawNextFrame()
        XCTAssertTrue(client.dataWaiting())
        assertUInt32Reply(expected: 6)

        // The command responses should only be pending, not sent yet.
        XCTAssertFalse(client.dataWaiting())

        // Put the command interface back into its normal "none" state.
        sendCommandCode(commandCode: mglFinishBatch)
        drawNextFrame()
        assertTimestampReply()
        XCTAssertEqual(commandInterface.getBatchState(), BatchState.none)

        // Expect a batch of results records.
        // These arrive in "vectorized" order, one field at a time across all records.
        // Command code.
        assertCommandCodeReply(expected: mglSetClearColor)
        assertCommandCodeReply(expected: mglFlush)
        assertCommandCodeReply(expected: mglSetClearColor)
        assertCommandCodeReply(expected: mglFlush)
        assertCommandCodeReply(expected: mglSetClearColor)
        assertCommandCodeReply(expected: mglFlush)

        // Status.
        for _ in 0..<6 { assertUInt32Reply(expected: 1) }

        // Processed Time
        for _ in 0..<6 { assertTimestampReply() }

        // Vertex start.
        for _ in 0..<6 { assertTimestampReply() }

        // Vertex end.
        for _ in 0..<6 { assertTimestampReply() }

        // Fragment start.
        for _ in 0..<6 { assertTimestampReply() }

        // Fragment end.
        for _ in 0..<6 { assertTimestampReply() }

        // Drawable acquired.
        for _ in 0..<6 { assertTimestampReply() }

        // Drawable presented.
        for _ in 0..<6 { assertTimestampReply() }

        XCTAssertFalse(client.dataWaiting())
    }

    func testPolygonViaClientBytes() {
        // Send a clear command with the color gray.
        sendCommandCode(commandCode: mglSetClearColor)
        sendColor(r: 0.25, g: 0.25, b: 0.25)

        // Send some rainbow polygon vertex data as [xyz rgb].
        sendCommandCode(commandCode: mglPolygon)
        sendUInt32(value: 5)
        sendXYZRGBVertex(x: -0.3, y: -0.4, z: 0.0, r: 1.0, g: 0.0, b: 0.0)
        sendXYZRGBVertex(x: -0.6, y: 0.1, z: 0.0, r: 1.0, g: 0.0, b: 0.0)
        sendXYZRGBVertex(x: 0.4, y: -0.2, z: 0.0, r: 0.0, g: 1.0, b: 0.0)
        sendXYZRGBVertex(x: -0.5, y: 0.5, z: 0.0, r: 0.0, g: 1.0, b: 1.0)
        sendXYZRGBVertex(x: 0.5, y: 0.3, z: 0.0, r: 0.0, g: 0.0, b: 1.0)

        // Send a flush command to present the clear color and polygon.
        sendCommandCode(commandCode: mglFlush)

        // Consume the commands and present a frame for visual inspection.
        drawNextFrame(sleepSecs: 0.5)

        // The server should send an ack timestamp for each command.
        // These look out of order here in this test because we're calling drawNextFrame() synchronously.
        // We don't want to enter the drawing tight loop until after sending the flush.
        // A client in another process should expect see interleaved ack, results, ack, results...
        assertTimestampReply()
        assertTimestampReply()
        assertTimestampReply()

        // The server should send a results record for the clear color and polygon commands.
        assertCommandResultsReply(commandCode: mglSetClearColor)
        assertCommandResultsReply(commandCode: mglPolygon)
        XCTAssertFalse(client.dataWaiting())

        // The last result record, for flush, waits until the start of the next frame.
        drawNextFrame()
        assertCommandResultsReply(commandCode: mglFlush)
        XCTAssertFalse(client.dataWaiting())
    }
}
