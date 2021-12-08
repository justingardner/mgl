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
        let originalValue = mglDots
        mglWriteCommandCode(testWriter, originalValue)
        let readValue = mglReadCommandCode(testReader)
        XCTAssertEqual(originalValue, readValue)
    }

    func testUInt32() throws {
        let originalValue = UInt32(12345)
        mglWriteUInt32(testWriter, originalValue)
        let readValue = mglReadUInt32(testReader)
        XCTAssertEqual(originalValue, readValue)
    }

    func testDouble() throws {
        let originalValue: Double = 1234.09876
        mglWriteDouble(testWriter, originalValue)
        let readValue = mglReadDouble(testReader)
        XCTAssertEqual(originalValue, readValue)
    }

    func testFloat() throws {
        let originalValue: Float = 1234.09876
        mglWriteFloat(testWriter, originalValue)
        let readValue = mglReadFloat(testReader)
        XCTAssertEqual(originalValue, readValue)
    }

    func testByterray() throws {
        let originalValue = (0..<512).map { _ in UInt8.random(in: 0...UInt8.max) }
        let expectedSize = 512
        let nWritten = originalValue.withUnsafeBufferPointer { originalValueBuffer in
            mglWriteByteArray(testWriter, originalValueBuffer.baseAddress, originalValue.count)
        }
        XCTAssertEqual(nWritten, expectedSize)

        var readValue = [UInt8](repeating: 0, count: originalValue.count)
        let nRead = readValue.withUnsafeMutableBufferPointer { readValueBuffer in
            mglReadByteArray(testReader, readValueBuffer.baseAddress, originalValue.count)
        }
        XCTAssertEqual(nRead, expectedSize)
        XCTAssertTrue(originalValue.elementsEqual(readValue))
    }

    func testUInt32Array() throws {
        let originalValue = (0..<128).map { _ in UInt32.random(in: 0...UInt32.max) }
        let expectedSize = mglSizeOfUInt32Array(originalValue.count)
        let nWritten = originalValue.withUnsafeBufferPointer { originalValueBuffer in
            mglWriteUInt32Array(testWriter, originalValueBuffer.baseAddress, originalValue.count)
        }
        XCTAssertEqual(nWritten, expectedSize)

        var readValue = [UInt32](repeating: 0, count: originalValue.count)
        let nRead = readValue.withUnsafeMutableBufferPointer { readValueBuffer in
            mglReadUInt32Array(testReader, readValueBuffer.baseAddress, originalValue.count)
        }
        XCTAssertEqual(nRead, expectedSize)
        XCTAssertTrue(originalValue.elementsEqual(readValue))
    }

    func testDoubleArray() throws {
        let originalValue = (0..<64).map { _ in Double.random(in: -1e6...1e6) }
        let expectedSize = mglSizeOfDoubleArray(originalValue.count)
        let nWritten = originalValue.withUnsafeBufferPointer { originalValueBuffer in
            mglWriteDoubleArray(testWriter, originalValueBuffer.baseAddress, originalValue.count)
        }
        XCTAssertEqual(nWritten, expectedSize)

        var readValue = [Double](repeating: 0, count: originalValue.count)
        let nRead = readValue.withUnsafeMutableBufferPointer { readValueBuffer in
            mglReadDoubleArray(testReader, readValueBuffer.baseAddress, originalValue.count)
        }
        XCTAssertEqual(nRead, expectedSize)
        XCTAssertTrue(originalValue.elementsEqual(readValue))
    }

    func testFloatArray() throws {
        let originalValue = (0..<128).map { _ in Float.random(in: -1e6...1e6) }
        let expectedSize = mglSizeOfFloatArray(originalValue.count)
        let nWritten = originalValue.withUnsafeBufferPointer { originalValueBuffer in
            mglWriteFloatArray(testWriter, originalValueBuffer.baseAddress, originalValue.count)
        }
        XCTAssertEqual(nWritten, expectedSize)

        var readValue = [Float](repeating: 0, count: originalValue.count)
        let nRead = readValue.withUnsafeMutableBufferPointer { readValueBuffer in
            mglReadFloatArray(testReader, readValueBuffer.baseAddress, originalValue.count)
        }
        XCTAssertEqual(nRead, expectedSize)
        XCTAssertTrue(originalValue.elementsEqual(readValue))
    }

    func testFloatRgb() throws {
        let originalValue: [Float] = [0.5, 0.75, 1.0]
        let expectedSize = mglSizeOfFloatRgb()
        let nWritten = originalValue.withUnsafeBufferPointer { originalValueBuffer in
            mglWriteFloatArray(testWriter, originalValueBuffer.baseAddress, originalValue.count)
        }
        XCTAssertEqual(nWritten, expectedSize)

        var readValue = [Float](repeating: 0, count: originalValue.count)
        let nRead = readValue.withUnsafeMutableBufferPointer { readValueBuffer in
            mglReadFloatArray(testReader, readValueBuffer.baseAddress, originalValue.count)
        }
        XCTAssertEqual(nRead, expectedSize)
        XCTAssertTrue(originalValue.elementsEqual(readValue))
    }

    func testFloat4x4Matrix() throws {
        let originalValue: [Float] = [1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0]
        let expectedSize = mglSizeOfFloat4x4Matrix()
        let nWritten = originalValue.withUnsafeBufferPointer { originalValueBuffer in
            mglWriteFloatArray(testWriter, originalValueBuffer.baseAddress, originalValue.count)
        }
        XCTAssertEqual(nWritten, expectedSize)

        var readValue = [Float](repeating: 0, count: originalValue.count)
        let nRead = readValue.withUnsafeMutableBufferPointer { readValueBuffer in
            mglReadFloatArray(testReader, readValueBuffer.baseAddress, originalValue.count)
        }
        XCTAssertEqual(nRead, expectedSize)
        XCTAssertTrue(originalValue.elementsEqual(readValue))
    }

    func testFloatVertexArray() throws {
        let nVertices = 32
        let nDimensions = 4
        let nElements = nVertices * nDimensions
        let originalValue = (0..<nElements).map { _ in Float.random(in: -1e6...1e6) }
        let expectedSize = mglSizeOfFloatVertexArray(nVertices, nDimensions)
        let nWritten = originalValue.withUnsafeBufferPointer { originalValueBuffer in
            mglWriteFloatArray(testWriter, originalValueBuffer.baseAddress, originalValue.count)
        }
        XCTAssertEqual(nWritten, expectedSize)

        var readValue = [Float](repeating: 0, count: originalValue.count)
        let nRead = readValue.withUnsafeMutableBufferPointer { readValueBuffer in
            mglReadFloatArray(testReader, readValueBuffer.baseAddress, originalValue.count)
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
        let expectedSize = mglSizeOfFloatRgbaTexture(width, height)
        let nWritten = originalValue.withUnsafeBufferPointer { originalValueBuffer in
            mglWriteFloatArray(testWriter, originalValueBuffer.baseAddress, originalValue.count)
        }
        XCTAssertEqual(nWritten, expectedSize)

        var readValue = [Float](repeating: 0, count: originalValue.count)
        let nRead = readValue.withUnsafeMutableBufferPointer { readValueBuffer in
            mglReadFloatArray(testReader, readValueBuffer.baseAddress, originalValue.count)
        }
        XCTAssertEqual(nRead, expectedSize)
        XCTAssertTrue(originalValue.elementsEqual(readValue))
    }
}

