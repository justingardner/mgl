//
//  mglCommandBytesTest.swift
//  mglMetalTests
//
//  Created by Benjamin Heasly on 12/8/21.
//  Copyright © 2021 GRU. All rights reserved.
//

import XCTest
@testable import mglMetal

class mglCommandBytesTest: XCTestCase {

    private static var mockSocket = [UInt8](repeating: 0x00, count: 512)

    private let testReader: mglReader = { (destinationBuffer: UnsafeMutableRawPointer?, n: size_t) -> size_t in
        mockSocket.withUnsafeMutableBytes { fakeStreamBytes in
            destinationBuffer!.copyMemory(from: fakeStreamBytes.baseAddress!, byteCount: n)
        }
        return n
    }

    private let testWriter: mglWriter = { (sourceBuffer: UnsafeRawPointer?, n: size_t) -> size_t in
        _ = mockSocket.withUnsafeMutableBytes { fakeStreamBytes in
            memcpy(fakeStreamBytes.baseAddress, sourceBuffer, n)
        }
        return n
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCommandCode() throws {
        let originalValue = dots
        writeCommandCode(testWriter, originalValue)
        let readValue = readCommandCode(testReader)
        XCTAssertEqual(originalValue, readValue)
    }

    func testUInt32() throws {
        let originalValue = UInt32(12345)
        writeUInt32(testWriter, originalValue)
        let readValue = readUInt32(testReader)
        XCTAssertEqual(originalValue, readValue)
    }

    func testDouble() throws {
        let originalValue: Double = 1234.09876
        writeDouble(testWriter, originalValue)
        let readValue = readDouble(testReader)
        XCTAssertEqual(originalValue, readValue)
    }

    func testFloat() throws {
        let originalValue: Float = 1234.09876
        writeFloat(testWriter, originalValue)
        let readValue = readFloat(testReader)
        XCTAssertEqual(originalValue, readValue)
    }

    func testUInt32Array() throws {
        let originalValue = (0..<128).map { _ in UInt32.random(in: 0...UInt32.max) }
        let expectedSize = sizeOfUInt32Array(originalValue.count)
        let nWritten = originalValue.withUnsafeBufferPointer { originalValueBuffer in
            writeUInt32Array(testWriter, originalValueBuffer.baseAddress, originalValue.count)
        }
        XCTAssertEqual(nWritten, expectedSize)

        var readValue = [UInt32](repeating: 0, count: originalValue.count)
        let nRead = readValue.withUnsafeMutableBufferPointer { readValueBuffer in
            readUInt32Array(testReader, readValueBuffer.baseAddress, originalValue.count)
        }
        XCTAssertEqual(nRead, expectedSize)
        XCTAssertTrue(originalValue.elementsEqual(readValue))
    }

    func testDoubleArray() throws {
        let originalValue = (0..<64).map { _ in Double.random(in: -1e6...1e6) }
        let expectedSize = sizeOfDoubleArray(originalValue.count)
        let nWritten = originalValue.withUnsafeBufferPointer { originalValueBuffer in
            writeDoubleArray(testWriter, originalValueBuffer.baseAddress, originalValue.count)
        }
        XCTAssertEqual(nWritten, expectedSize)

        var readValue = [Double](repeating: 0, count: originalValue.count)
        let nRead = readValue.withUnsafeMutableBufferPointer { readValueBuffer in
            readDoubleArray(testReader, readValueBuffer.baseAddress, originalValue.count)
        }
        XCTAssertEqual(nRead, expectedSize)
        XCTAssertTrue(originalValue.elementsEqual(readValue))
    }

    func testFloatArray() throws {
        let originalValue = (0..<128).map { _ in Float.random(in: -1e6...1e6) }
        let expectedSize = sizeOfFloatArray(originalValue.count)
        let nWritten = originalValue.withUnsafeBufferPointer { originalValueBuffer in
            writeFloatArray(testWriter, originalValueBuffer.baseAddress, originalValue.count)
        }
        XCTAssertEqual(nWritten, expectedSize)

        var readValue = [Float](repeating: 0, count: originalValue.count)
        let nRead = readValue.withUnsafeMutableBufferPointer { readValueBuffer in
            readFloatArray(testReader, readValueBuffer.baseAddress, originalValue.count)
        }
        XCTAssertEqual(nRead, expectedSize)
        XCTAssertTrue(originalValue.elementsEqual(readValue))
    }

    func testFloatRgb() throws {
        let originalValue: [Float] = [0.5, 0.75, 1.0]
        let expectedSize = sizeOfFloatRgb()
        let nWritten = originalValue.withUnsafeBufferPointer { originalValueBuffer in
            writeFloatArray(testWriter, originalValueBuffer.baseAddress, originalValue.count)
        }
        XCTAssertEqual(nWritten, expectedSize)

        var readValue = [Float](repeating: 0, count: originalValue.count)
        let nRead = readValue.withUnsafeMutableBufferPointer { readValueBuffer in
            readFloatArray(testReader, readValueBuffer.baseAddress, originalValue.count)
        }
        XCTAssertEqual(nRead, expectedSize)
        XCTAssertTrue(originalValue.elementsEqual(readValue))
    }

    func testFloat4x4Matrix() throws {
        let originalValue: [Float] = [1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0]
        let expectedSize = sizeOfFloat4x4Matrix()
        let nWritten = originalValue.withUnsafeBufferPointer { originalValueBuffer in
            writeFloatArray(testWriter, originalValueBuffer.baseAddress, originalValue.count)
        }
        XCTAssertEqual(nWritten, expectedSize)

        var readValue = [Float](repeating: 0, count: originalValue.count)
        let nRead = readValue.withUnsafeMutableBufferPointer { readValueBuffer in
            readFloatArray(testReader, readValueBuffer.baseAddress, originalValue.count)
        }
        XCTAssertEqual(nRead, expectedSize)
        XCTAssertTrue(originalValue.elementsEqual(readValue))
    }

    func testFloatVertexArray() throws {
        let nVertices = 32
        let nDimensions = 4
        let nElements = nVertices * nDimensions
        let originalValue = (0..<nElements).map { _ in Float.random(in: -1e6...1e6) }
        let expectedSize = sizeOfFloatVertexArray(nVertices, nDimensions)
        let nWritten = originalValue.withUnsafeBufferPointer { originalValueBuffer in
            writeFloatArray(testWriter, originalValueBuffer.baseAddress, originalValue.count)
        }
        XCTAssertEqual(nWritten, expectedSize)

        var readValue = [Float](repeating: 0, count: originalValue.count)
        let nRead = readValue.withUnsafeMutableBufferPointer { readValueBuffer in
            readFloatArray(testReader, readValueBuffer.baseAddress, originalValue.count)
        }
        XCTAssertEqual(nRead, expectedSize)
        XCTAssertTrue(originalValue.elementsEqual(readValue))
    }

    func testFloatRgbaTexture() throws {
        let width = 4
        let height = 8
        let nDimensions = 4
        let nElements = width * height * nDimensions
        let originalValue = (0..<nElements).map { _ in Float.random(in: -1e6...1e6) }
        let expectedSize = sizeOfFloatRgbaTexture(width, height)
        let nWritten = originalValue.withUnsafeBufferPointer { originalValueBuffer in
            writeFloatArray(testWriter, originalValueBuffer.baseAddress, originalValue.count)
        }
        XCTAssertEqual(nWritten, expectedSize)

        var readValue = [Float](repeating: 0, count: originalValue.count)
        let nRead = readValue.withUnsafeMutableBufferPointer { readValueBuffer in
            readFloatArray(testReader, readValueBuffer.baseAddress, originalValue.count)
        }
        XCTAssertEqual(nRead, expectedSize)
        XCTAssertTrue(originalValue.elementsEqual(readValue))
    }
}

