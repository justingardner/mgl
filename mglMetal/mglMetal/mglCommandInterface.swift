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
        // read 2 bytes of raw data
        let rawData = communicator.readData(2);
        // convert to mglCommands
        let convertedData = rawData.bindMemory(to: mglCommands.self, capacity: 1)
        // return what it points to
        return(convertedData.pointee)
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
        // read 2 bytes of raw data
        let rawData = communicator.readData(4);
        // convert to UInt32
        let convertedData = rawData.bindMemory(to: UInt32.self, capacity: 1)
        // return what it points to
        return(convertedData.pointee)
    }
}
