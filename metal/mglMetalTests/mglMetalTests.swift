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

    func assertTimestampReplies(count: Int, atLeast: Double = 1.0) {
        var timestamps = [Double](repeating: 0, count: count)
        let bytesRead = timestamps.withUnsafeMutableBufferPointer {
            client.readData(buffer: $0.baseAddress!, expectedByteCount: 8 * count)
        }
        XCTAssertEqual(bytesRead, 8 * count)

        for timestamp in timestamps {
            XCTAssertGreaterThanOrEqual(timestamp, atLeast)
        }
    }

    func assertUInt32Reply(expected: UInt32) {
        var value = UInt32(0)
        let bytesRead = client.readData(buffer: &value, expectedByteCount: 4)
        XCTAssertEqual(bytesRead, 4)
        XCTAssertEqual(value, expected)
    }

    private func sendCommandCode(code: mglCommandCode) {
        var codeValue = code.rawValue
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

    func assertViewClearColor(r: Double, g: Double, b: Double) {
        XCTAssertEqual(view.clearColor.red, r)
        XCTAssertEqual(view.clearColor.green, g)
        XCTAssertEqual(view.clearColor.blue, b)
        XCTAssertEqual(view.clearColor.alpha, 1.0)
    }

    func testClearColorViaClientBytes() {
        // Send a clear command with the color green.
        sendCommandCode(code: mglSetClearColor)
        sendColor(r: 0.0, g: 1.0, b: 0.0)

        // Send a flush command to present the new clear color.
        sendCommandCode(code: mglFlush)

        // Consume the clear and flush commands and present a frame for visual inspection.
        drawNextFrame(sleepSecs: 0.5)

        // Processing the clear command should also set the view clear color.
        assertViewClearColor(r: 0.0, g: 1.0, b: 0.0)

        // The server should send 3 timestamps right away:
        //  - ack for clear
        //  - processed for clear
        //  - ack for flush
        assertTimestampReplies(count: 3)
        XCTAssertFalse(client.dataWaiting())

        // The last timestamp, processed for flush, waits until the start of the next frame.
        drawNextFrame()
        assertTimestampReplies(count: 1)
        XCTAssertFalse(client.dataWaiting())
    }

    private func assertSuccess(command: mglCommand, startTime: Double = 0.0) {
        XCTAssertTrue(command.results.success)
        XCTAssertGreaterThan(command.results.ackTime, startTime)
        XCTAssertGreaterThan(command.results.processedTime, command.results.ackTime)
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
        sendCommandCode(code: mglStartBatch)
        drawNextFrame()
        assertTimestampReplies(count: 1)
        XCTAssertEqual(commandInterface.getBatchState(), BatchState.building)

        // Send several pairs of set-clear-color and flush commands.
        // Each one should get back an ack time and a placeholder "processed" time.
        // Red
        sendCommandCode(code: mglSetClearColor)
        sendColor(r: 1.0, g: 0.0, b: 0.0)
        drawNextFrame()
        assertTimestampReplies(count: 1)
        assertTimestampReplies(count: 1, atLeast: 0.0)

        sendCommandCode(code: mglFlush)
        drawNextFrame()
        assertTimestampReplies(count: 1)
        assertTimestampReplies(count: 1, atLeast: 0.0)

        // Green
        sendCommandCode(code: mglSetClearColor)
        sendColor(r: 0.0, g: 1.0, b: 0.0)
        drawNextFrame()
        assertTimestampReplies(count: 1)
        assertTimestampReplies(count: 1, atLeast: 0.0)

        sendCommandCode(code: mglFlush)
        drawNextFrame()
        assertTimestampReplies(count: 1)
        assertTimestampReplies(count: 1, atLeast: 0.0)

        // Blue
        sendCommandCode(code: mglSetClearColor)
        sendColor(r: 0.0, g: 0.0, b: 1.0)
        drawNextFrame()
        assertTimestampReplies(count: 1)
        assertTimestampReplies(count: 1, atLeast: 0.0)

        sendCommandCode(code: mglFlush)
        drawNextFrame()
        assertTimestampReplies(count: 1)
        assertTimestampReplies(count: 1, atLeast: 0.0)

        // These commands should all be enqueued as todo, and not yet processed or reported.
        XCTAssertFalse(client.dataWaiting())

        // Since the commands aren't processed yet, the view's clear color should be default gray.
        assertViewClearColor(r: 0.5, g: 0.5, b: 0.5)

        // Put the command interface into batch "processing" state.
        sendCommandCode(code: mglProcessBatch)
        drawNextFrame(sleepSecs: 0.5)
        assertTimestampReplies(count: 1)
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
        // This also tells us how many responses are pending, in this case 6.
        drawNextFrame()
        XCTAssertTrue(client.dataWaiting())
        assertUInt32Reply(expected: 6)

        // The command responses should only be pending, not sent yet.
        XCTAssertFalse(client.dataWaiting())

        // Put the command interface back into its normal "none" state.
        sendCommandCode(code: mglFinishBatch)
        drawNextFrame()
        assertTimestampReplies(count: 1)
        XCTAssertEqual(commandInterface.getBatchState(), BatchState.none)

        // Expect 6 timestamp replies, one for each command.
        assertTimestampReplies(count: 6)
        XCTAssertFalse(client.dataWaiting())
    }
}
