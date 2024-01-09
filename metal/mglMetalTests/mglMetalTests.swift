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

    private func drawNextFrame(sleepTime: TimeInterval = TimeInterval.zero) {
        view.draw()
        if (sleepTime > TimeInterval.zero) {
            Thread.sleep(forTimeInterval: sleepTime)
        }
    }

    func assertTimestamps(count: Int, greaterThan: Double = 0.0) {
        var timestamps = [Double](repeating: 0, count: count)
        let bytesRead = timestamps.withUnsafeMutableBufferPointer {
            client.readData(buffer: $0.baseAddress!, expectedByteCount: 8 * count)
        }
        XCTAssertEqual(bytesRead, 8 * count)

        for timestamp in timestamps {
            XCTAssertGreaterThan(timestamp, greaterThan)
        }
    }

    func testClearColorViaClientBytes() {
        // Send a clear command with the color green.
        let clear: [UInt16] = [mglSetClearColor.rawValue]
        let clearBytesSent = clear.withUnsafeBufferPointer {
            client.sendData(buffer: $0.baseAddress!, byteCount: 2)
        }
        XCTAssertEqual(clearBytesSent, 2)

        let green: [Float32] = [0.0, 1.0, 0.0]
        let greenBytesSent = green.withUnsafeBufferPointer {
            client.sendData(buffer: $0.baseAddress!, byteCount: 12)
        }
        XCTAssertEqual(greenBytesSent, 12)

        // Send a flush command to present the new clear color.
        let flush: [UInt16] = [mglFlush.rawValue]
        let flushBytesSent = flush.withUnsafeBufferPointer {
            client.sendData(buffer: $0.baseAddress!, byteCount: 2)
        }
        XCTAssertEqual(flushBytesSent, 2)

        // Consume the clear and flush commands and present a frame for visual inspection.
        drawNextFrame(sleepTime: TimeInterval(1.0))

        // Processing the clear command should also set the view clear color.
        XCTAssertEqual(view.clearColor.red, 0.0)
        XCTAssertEqual(view.clearColor.green, 1.0)
        XCTAssertEqual(view.clearColor.blue, 0.0)
        XCTAssertEqual(view.clearColor.alpha, 1.0)

        // The server should send 3 timestamps right away:
        //  - ack for clear
        //  - processed for clear
        //  - ack for flush
        assertTimestamps(count: 3)
        XCTAssertFalse(client.dataWaiting())

        // The last timestamp, processed for flush, waits until the start of the next frame.
        drawNextFrame()
        assertTimestamps(count: 1)
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
        XCTAssertEqual(view.clearColor.red, 0.0)
        XCTAssertEqual(view.clearColor.green, 0.0)
        XCTAssertEqual(view.clearColor.blue, 1.0)
        XCTAssertEqual(view.clearColor.alpha, 1.0)

        // Processing the flush command should draw the clear color to all pixels.
        let expectedPixel = RGBAFloat32Pixel(r: 0.0, g: 0.0, b: 1.0, a: 1.0)
        assertAllOffscreenPixels(expectedPixel: expectedPixel)

        // The the processed time for the flush command waits until the start of the next frame.
        drawNextFrame()
        assertSuccess(command: flush)
    }
}
