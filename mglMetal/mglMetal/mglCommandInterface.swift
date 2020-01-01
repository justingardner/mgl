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
// A class which abstracts the mglCommunicatorProtocol
// The ideas is that mglCommunicatorSocket which implements
// the mglCommunicatorProtocol could be swaped
// out with some other class that implements the protocol over
// somet other way of communicating (e.g. shared memory) in
// the future. This class then provides a programmatically
// easy way to access data from matlab
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
class mglCommandInterface {
    // variable to hold mglCommunicator which
    // communicates with matlab
    var communicator : mglCommunicatorSocket
    
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // init
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    init() {
        // Setup communication with matlab
        communicator = mglCommunicatorSocket()
        do {
            try communicator.open("testsocket")
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
    func readCommand() -> mglCommands {
        // allocate data
        let command = UnsafeMutablePointer<mglCommands>.allocate(capacity: 1)
        defer {
          command.deallocate()
        }
        // read 2 bytes of raw data
        communicator.readData(2, buf: command);
        // return what it points to
        return(command.pointee)
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
        // allocate data
        let data = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)
        defer {
          data.deallocate()
        }
        // read 4 bytes of raw data
        communicator.readData(4,buf:data);
        // return what it points to
        return(data.pointee)
    }
    
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // readData
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func readData(count: Int, buf: UnsafeMutableRawPointer) {
        // read data
        communicator.readData(Int32(count),buf:buf);
    }
    
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // readColor
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func readColor() -> simd_float3 {
        // allocate data
        let data = UnsafeMutablePointer<simd_float3>.allocate(capacity: 1)
        defer {
          data.deallocate()
        }

        // read 12 bytes of raw data
        communicator.readData(4*3,buf:data);

        // return what it points to
        return(data.pointee)
    }
    
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // readVertices
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func readVertices(device: MTLDevice, extraVals: Int = 0) -> (buffer: MTLBuffer, vertexCount: Int) {
        // Get the number of vertices
        let vertexCount = Int(readUInt32())
        print("(commandInterface:readVerticesWithColor) VertexCount: \(vertexCount)")
        
        // calculate how many floats we have per vertex. ExtraVals can be used
        // for things like color or texture coordinates
        let valsPerVertex = 3 + extraVals
        
        // get an MTLBuffer from the GPU
        guard let vertexBuffer = device.makeBuffer(length: vertexCount * valsPerVertex * MemoryLayout<Float>.stride) else {
            fatalError("(mglMetal:mglCommandInterface) Could not make vertex buffer of size \(vertexCount) * \(valsPerVertex) * \(MemoryLayout<Float>.stride)")
        }
        
        // Read the data into the MTLBuffer
        readData(count: vertexCount * valsPerVertex * MemoryLayout<Float>.stride, buf: vertexBuffer.contents())
        
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
        let textureSize = textureWidth * textureHeight * 4 * MemoryLayout<Float>.size
        
        // get an MTLBuffer from the GPU to store image data in
        guard let textureBuffer = device.makeBuffer(length: textureSize, options: .storageModeManaged) else {
            fatalError("(mglMetal:mglCommandInterface) Could not make texture buffer of size:  \(textureWidth) * \(textureHeight)")
        }
        
        // Read the data into the MTLBuffer
        readData(count: textureSize, buf: textureBuffer.contents())
        
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
        // allocate data
        let data = UnsafeMutablePointer<simd_float4x4>.allocate(capacity: 1)
        defer {
          data.deallocate()
        }

        // read 4 bytes of raw data
        communicator.readData(4*4*4,buf:data);

        // return what it points to
        return(data.pointee)
    }
    
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // writeDouble
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func writeDouble(data: Double) {
        // pass on to communicator
        communicator.writeDataDouble(data);
    }

}
