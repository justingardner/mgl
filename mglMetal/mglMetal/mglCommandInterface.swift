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
    // readVertices
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func readVertices(device: MTLDevice) -> MTLBuffer {
        // Get the number of vertices
        let vertexCount = Int(readUInt32())
        print("(commandInterface:readVertices) VertexCount: \(vertexCount)")
        let vertexBuffer = device.makeBuffer(length: vertexCount * 3 * MemoryLayout<Float>.stride)
        // read the vertex data from the command interface
        // FIX do proper error checking here
        readData(count: vertexCount * 3 * MemoryLayout<Float>.stride, buf: vertexBuffer!.contents())
        // return the buffer
        return(vertexBuffer!)
    }
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // writeDouble
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func writeDouble(data: Double) {
        // pass on to communicator
        communicator.writeDataDouble(data);
    }

}
