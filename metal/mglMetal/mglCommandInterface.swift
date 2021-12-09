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
// A class which builds on the mglCommunicatorProtocol
// to safely read and write supported data types to
// and from a byte stream.  This uses the header
// mglCommandBytes.h, which is also used by Matlab.
//
// This opens a connection to Matlab based on a socket
// address passed as a command line option:
//   mglMetal ... -mglConnectionAddress my-address
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
class mglCommandInterface {
    let communicator: mglCommunicatorProtocol = mglCommunicatorSocket()

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // init
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    init() {
        // Get the socket address to use from the command line
        let arguments = CommandLine.arguments
        guard let optionIndex = arguments.firstIndex(of: "-mglConnectionAddress"),
              let address = arguments.indices.contains(optionIndex + 1) ? arguments[optionIndex + 1] : nil else {
                  print("(mglCommandInterface) no value given for -mglConnectionAddress on command line, running with no connection.")
                  return;
              }

        print("(mglCommandInterface) using socket address \(address)")
        do {
            try communicator.open(address)
        }
        catch let error as NSError {
            fatalError("(mglCommunicator) Error: \(error.domain) \(error.localizedDescription)")
        }
    }
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // deinit
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    deinit {
        // close the socket
        communicator.close()
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // readCommand
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func readCommand() -> mglCommandCode {
        return mglReadCommandCode(communicator.reader());
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // dataWaiting
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func dataWaiting() -> Bool {
        return communicator.dataWaiting()
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // readUINT32
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func readUInt32() -> UInt32 {
        return mglReadUInt32(communicator.reader());
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // readFloat
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func readFloat() -> Float {
        return mglReadFloat(communicator.reader());
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // readColor
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func readColor() -> simd_float3 {
        // Read plain old float array from the socket.
        let data = UnsafeMutablePointer<Float>.allocate(capacity: 3)
        defer {
            data.deallocate()
        }
        mglReadFloatArray(communicator.reader(), data, 3);

        // Let the library decide how simd vectors are aligned and packed.
        return(simd_make_float3(data[0], data[1], data[2]))
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // readVertices
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func readVertices(device: MTLDevice, extraVals: Int = 0) -> (buffer: MTLBuffer, vertexCount: Int) {
        // Get the number of vertices
        let vertexCount = Int(readUInt32())
        print("(commandInterface:readVertices) VertexCount: \(vertexCount)")

        // calculate how many floats we have per vertex. ExtraVals can be used
        // for things like color or texture coordinates
        let valsPerVertex = 3 + extraVals
        let bufferSize = mglSizeOfFloatVertexArray(vertexCount, valsPerVertex)

        // get an MTLBuffer from the GPU
        guard let vertexBuffer = device.makeBuffer(length: bufferSize) else {
            fatalError("(commandInterface:readVertices) Could not make vertex buffer of size \(bufferSize)")
        }

        // Read the data into the MTLBuffer
        mglReadByteArray(communicator.reader(), vertexBuffer.contents(), bufferSize)

        // return the MTLBuffer
        return(vertexBuffer, vertexCount)
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // readTexture
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func readTexture(device: MTLDevice) -> MTLTexture {
        // Read the texture width and height
        let textureWidth = Int(readUInt32())
        let textureHeight = Int(readUInt32())
        print("(commandInterface:readTexture) textureWidth: \(textureWidth) textureHeight: \(textureHeight)")

        // set the texture descriptor
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba32Float,
            width: Int(textureWidth),
            height: Int(textureHeight),
            mipmapped: false)

        // compute size of texture in bytes (4 is for RGBA)
        let textureSize = mglSizeOfFloatRgbaTexture(textureWidth, textureHeight)

        // get an MTLBuffer from the GPU to store image data in
        guard let textureBuffer = device.makeBuffer(length: textureSize, options: .storageModeManaged) else {
            fatalError("(mglMetal:mglCommandInterface) Could not make texture buffer of size:  \(textureWidth) * \(textureHeight)")
        }

        // Read the data into the MTLBuffer
        mglReadByteArray(communicator.reader(), textureBuffer.contents(), textureSize)

        // Now make the buffer into a texture
        guard let texture = textureBuffer.makeTexture(descriptor: textureDescriptor, offset: 0, bytesPerRow: textureWidth * 4 * MemoryLayout<Float>.size) else {
            fatalError("(mglMetal:mglCommandInterface) Could not make texture from texture buffer of size:  \(textureWidth) * \(textureHeight)")
        }
        print("mglMetal:mglCommandInterface) Created texture: \(textureWidth) x \(textureHeight)")

        // return the texture
        return(texture)
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // readXform
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func readXform() -> simd_float4x4 {
        // Read plain old float array from the socket.
        let dataBytes = mglSizeOfFloat4x4Matrix()
        print("I want a transform of \(dataBytes) bytes.")
        let data = UnsafeMutablePointer<Float>.allocate(capacity: 16)
        defer {
            data.deallocate()
        }
        mglReadFloatArray(communicator.reader(), data, 16);

        print("I got a transform.")

        // Let the library decide how simd vectors are aligned and packed.
        let column0 = simd_make_float4(data[0], data[1], data[2], data[3])
        let column1 = simd_make_float4(data[4], data[5], data[6], data[7])
        let column2 = simd_make_float4(data[8], data[9], data[10], data[11])
        let column3 = simd_make_float4(data[12], data[13], data[14], data[15])
        return(simd_float4x4(column0, column1, column2, column3))
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // writeDouble
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func writeDouble(data: Double) {
        mglWriteDouble(communicator.writer(), data)
    }

}
