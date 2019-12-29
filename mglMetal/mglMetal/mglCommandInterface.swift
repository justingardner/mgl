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
    func readUINT32() -> UInt32 {
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
    // readFloats
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func readFloats(count: Int) -> UnsafeBufferPointer<Float> {
        // allocate data
        let data = UnsafeMutablePointer<Float>.allocate(capacity: count)
        defer {
          data.deallocate()
        }
        // read 4 bytes of raw data
        communicator.readData(Int32(count*MemoryLayout<Float>.stride),buf:data);
        // return what it points to
        return(UnsafeBufferPointer(start: data, count: count))
    }
}
