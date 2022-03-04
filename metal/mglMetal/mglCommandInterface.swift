//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
//
//  mglCommandInterface.swift
//  mglMetal
//
//  Created by justin gardner on 12/29/2019.
//  Copyright © 2019 GRU. All rights reserved.
//
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/

import Foundation
import MetalKit

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// This class combines an mglServer instance with
// the header mglCommandTypes.h, which is also used
// in our Matlab code, to safely read and write
// supported commands and data types.
//
// This opens a connection to Matlab based on a
// connection address passed as a command line option:
//   mglMetal ... -mglConnectionAddress my-address
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
class mglCommandInterface {
    private let server: mglServer

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // init
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    init() {
        // Get the connection address to use from the command line
        let arguments = CommandLine.arguments
        let optionIndex = arguments.firstIndex(of: "-mglConnectionAddress") ?? -2
        if optionIndex < 0 {
            print("(mglCommandInterface) no command line option passed for -mglConnectionAddress, using a default address.")
        }
        let address = arguments.indices.contains(optionIndex + 1) ? arguments[optionIndex + 1] : "mglMetal.socket"
        print("(mglCommandInterface) using connection address \(address)")

        // In the future we might inspect the address to decide what kind of server to create,
        // like local socket vs internet socket, vs shared memory, etc.
        // For now, we always interpret the address as a file system path for a local socket.
        server = mglLocalServer(pathToBind: address)
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // waitForClientToConnect
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func acceptClientConnection() -> Bool {
        return server.acceptClientConnection()
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // dataWaiting
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func dataWaiting() -> Bool {
        return server.dataWaiting()
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // readCommand
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func readCommand() -> mglCommandCode {
        var data = mglUnknownCommand
        let expectedByteCount = MemoryLayout<mglCommandCode>.size
        let bytesRead = server.readData(buffer: &data, expectedByteCount: expectedByteCount)
        if (bytesRead != expectedByteCount) {
            fatalError("(mglCommandInterface:readCommand) Expected to read \(expectedByteCount) bytes but read \(bytesRead)")
        }
        return data
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // readUINT32
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func readUInt32() -> mglUInt32 {
        var data = mglUInt32(0)
        let expectedByteCount = MemoryLayout<mglUInt32>.size
        let bytesRead = server.readData(buffer: &data, expectedByteCount: expectedByteCount)
        if (bytesRead != expectedByteCount) {
            fatalError("(mglCommandInterface:readUInt32) Expected to read \(expectedByteCount) bytes but read \(bytesRead)")
        }
        return data
    }

    func writeUInt32(data: mglUInt32) -> Int {
        var localData = data
        let expectedByteCount = MemoryLayout<mglUInt32>.size
        return server.sendData(buffer: &localData, byteCount: expectedByteCount)
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // readFloat
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func readFloat() -> mglFloat {
        var data = mglFloat(0)
        let expectedByteCount = MemoryLayout<mglFloat>.size
        let bytesRead = server.readData(buffer: &data, expectedByteCount: expectedByteCount)
        if (bytesRead != expectedByteCount) {
            fatalError("(mglCommandInterface:readFloat) Expected to read \(expectedByteCount) bytes but read \(bytesRead)")
        }
        return data
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // readColor
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func readColor() -> simd_float3 {
        let data = UnsafeMutablePointer<Float>.allocate(capacity: 3)
        defer {
            data.deallocate()
        }

        let expectedByteCount = Int(mglSizeOfFloatRgbColor())
        let bytesRead = server.readData(buffer: data, expectedByteCount: expectedByteCount)
        if (bytesRead != expectedByteCount) {
            fatalError("(mglCommandInterface:readColor) Expected to read \(expectedByteCount) bytes but read \(bytesRead)")
        }

        // Let the library decide how simd vectors are packed.
        return simd_make_float3(data[0], data[1], data[2])
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // readXform
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func readXform() -> simd_float4x4 {
        let data = UnsafeMutablePointer<Float>.allocate(capacity: 16)
        defer {
            data.deallocate()
        }

        let expectedByteCount = Int(mglSizeOfFloat4x4Matrix())
        let bytesRead = server.readData(buffer: data, expectedByteCount: expectedByteCount)
        if (bytesRead != expectedByteCount) {
            fatalError("(mglCommandInterface:readXform) Expected to read \(expectedByteCount) bytes but read \(bytesRead)")
        }

        // Let the library decide how simd vectors are packed.
        let column0 = simd_make_float4(data[0], data[1], data[2], data[3])
        let column1 = simd_make_float4(data[4], data[5], data[6], data[7])
        let column2 = simd_make_float4(data[8], data[9], data[10], data[11])
        let column3 = simd_make_float4(data[12], data[13], data[14], data[15])
        return(simd_float4x4(column0, column1, column2, column3))
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // readVertices
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func readVertices(device: MTLDevice, extraVals: Int = 0) -> (buffer: MTLBuffer, vertexCount: Int) {
        // Get the number of vertices
        let vertexCount = Int(readUInt32())
        print("(mglCommandInterface:readVertices) vertexCount: \(vertexCount)")

        // Calculate how many floats we have per vertex.
        // Start with 3 for XYZ, plus extraVals which can be used for things like color or texture coordinates.
        let valsPerVertex = mglUInt32(3 + extraVals)
        let expectedByteCount = Int(mglSizeOfFloatVertexArray(mglUInt32(vertexCount), valsPerVertex))

        // get an MTLBuffer from the GPU
        // With storageModeManaged, we must explicitly sync the data to the GPU, below.
        guard let vertexBuffer = device.makeBuffer(length: expectedByteCount, options: .storageModeManaged) else {
            fatalError("(mglCommandInterface:readVertices) Could not make vertex buffer of size \(expectedByteCount)")
        }

        let bytesRead = server.readData(buffer: vertexBuffer.contents(), expectedByteCount: expectedByteCount)
        if (bytesRead != expectedByteCount) {
            fatalError("(mglCommandInterface:readVertices) Expected to read \(expectedByteCount) bytes but read \(bytesRead)")
        }

        // With storageModeManaged above, we must explicitly sync the new data to the GPU.
        vertexBuffer.didModifyRange( 0 ..< expectedByteCount)
        return (vertexBuffer, vertexCount)
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // readTexture
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func readTexture(device: MTLDevice) -> MTLTexture {
        // Read the texture width and height
        let textureWidth = Int(readUInt32())
        let textureHeight = Int(readUInt32())
        print("(mglCommandInterface:readTexture) textureWidth: \(textureWidth) textureHeight: \(textureHeight)")

        // Set the texture descriptor
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba32Float,
            width: Int(textureWidth),
            height: Int(textureHeight),
            mipmapped: false)

        // Compute size of texture in bytes
        let expectedByteCount = Int(mglSizeOfFloatRgbaTexture(mglUInt32(textureWidth), mglUInt32(textureHeight)))

        // Get an MTLBuffer from the GPU to store image data in
        // With storageModeManaged, we must explicitly sync the data to the GPU, below.
        guard let textureBuffer = device.makeBuffer(length: expectedByteCount, options: .storageModeManaged) else {
            fatalError("(mglCommandInterface:readTexture) Could not make texture buffer of size \(expectedByteCount) width: \(textureWidth) height: \(textureHeight)")
        }

        let bytesRead = server.readData(buffer: textureBuffer.contents(), expectedByteCount: expectedByteCount)
        if (bytesRead != expectedByteCount) {
            fatalError("(mglCommandInterface:readTexture) Expected to read \(expectedByteCount) bytes but read \(bytesRead)")
        }

        // With storageModeManaged above, we must explicitly sync the new data to the GPU.
        textureBuffer.didModifyRange(0 ..< expectedByteCount)

        // Now make the buffer into a texture
        let bytesPerRow = expectedByteCount / textureHeight
        guard let texture = textureBuffer.makeTexture(descriptor: textureDescriptor, offset: 0, bytesPerRow: bytesPerRow) else {
            fatalError("(mglCommandInterface:readTexture) Could not make texture from texture buffer of size \(expectedByteCount) width: \(textureWidth) height")
        }

        print("mglCommandInterface:readTexture) Created texture: \(textureWidth) x \(textureHeight)")
        return(texture)
    }

    func writeDouble(data: Double) -> Int {
        var localData = data
        let expectedByteCount = MemoryLayout<mglDouble>.size
        return server.sendData(buffer: &localData, byteCount: expectedByteCount)
    }

    func writeCommand(data: mglCommandCode) -> Int {
        var localData = data
        let expectedByteCount = MemoryLayout<mglCommandCode>.size
        return server.sendData(buffer: &localData, byteCount: expectedByteCount)
    }
}
