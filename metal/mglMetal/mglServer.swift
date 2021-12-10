//
//  mglServer.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 12/10/21.
//  Copyright © 2021 GRU. All rights reserved.
//

import Foundation

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Protocol for communication with matlab.
// This defines a set of methods that can be used
// to accept connections, read, and write to matlab.
//
// It is declared as a protocol so that future
// versions of the code need simply conform to this
// protocol and can replace the underlying
// communication strucutre.
//
// This protocol assumes implementations use the
// RAII pattern, which means system Resources
// are Acquired during Initialization ie init(),
// and then released during deinitialization ie
// deinit {}.  For sockets this would include
// creating and binding a socket to some address.
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
protocol mglServer {
    // Accept a client connection if not already accepted, return immediately either way.
    func acceptClientConnection() -> Bool

    // Check if data has arrived from the client, return immediately either way.
    func dataWaiting() -> Bool

    // Read data from the client.
    // Block until all of the expected bytes have arrived, or an error.
    // Return the number of bytes actually read, or some error code.
    func readData(buffer: UnsafeMutableRawPointer, expectedByteCount: Int) -> Int

    // Write data to the client.
    // Return the number of bytes actually written, or some error code.
    func sendData(buffer: UnsafeRawPointer, byteCount: Int) -> Int
}
