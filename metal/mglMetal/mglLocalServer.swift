//
//  mglSocketServer.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 12/9/21.
//  Copyright © 2021 GRU. All rights reserved.
//

import Foundation

class mglLocalServer : mglServer {

    let pathToBind: String
    let maxConnections: Int32 = Int32(500)
    let pollMilliseconds: Int32 = Int32(10)

    let boundSocketDescriptor: Int32
    var acceptedSocketDescriptor: Int32 = -1

    init(pathToBind: String, maxConnections: Int32 = Int32(500), pollMilliseconds: Int32 = Int32(10)) {
        print("(mglLocalServer) Starting with path to bind: \(pathToBind)")
        self.pathToBind = pathToBind

        if FileManager.default.fileExists(atPath: pathToBind) {
            let url = URL(fileURLWithPath: pathToBind)
            do {
                try FileManager.default.removeItem(at: url)
            } catch let error as NSError {
                fatalError("(mglLocalServer) Unable to remove existing file\(pathToBind): \(error)")
            }
        }

        boundSocketDescriptor = socket(AF_UNIX, SOCK_STREAM, 0)
        if boundSocketDescriptor < 0 {
            fatalError("(mglLocalServer) Could not create socket: \(boundSocketDescriptor) errno: \(errno)")
        }

        let nonblockingResult = fcntl(boundSocketDescriptor, F_SETFL, O_NONBLOCK)
        if nonblockingResult < 0 {
            fatalError("(mglLocalServer) Could not set socket to nonblocking: \(nonblockingResult) errno: \(errno)")
        }

        var address = sockaddr_un()
        address.sun_family = UInt8(AF_UNIX)
        address.sun_len = UInt8(MemoryLayout<sockaddr_un>.size)
        strlcpy(&address.sun_path.0, pathToBind, MemoryLayout.size(ofValue: address.sun_path))

        // Some interesting swift-c interop here.
        // withUnsafePointer gives us a c-style-pointer to the address struct, which has concrete type sockaddr_un.
        // withMemoryRebound gives us a view of the same pointer, but "cast" to the generic sockaddr type that bind() wants.
        // $0 is an automatic parameter name that can be used in each {} block.
        let addressLength = socklen_t(address.sun_len)
        let bindResult = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(boundSocketDescriptor, $0, addressLength)
            }
        }

        if bindResult < 0 {
            fatalError("(mglLocalServer) Could not bind the path \(pathToBind) with result: \(bindResult) errno: \(errno)")
        }

        let listenResult = listen(boundSocketDescriptor, maxConnections)
        if listenResult < 0 {
            fatalError("(mglLocalServer) Could not listen for connections: \(listenResult) errno: \(errno)")
        }

        print("(mglLocalServer) ready and listening for connections at path: \(pathToBind)")
    }

    deinit {
        disconnect()
        if boundSocketDescriptor != -1 {
            close(boundSocketDescriptor);
        }
    }

    func clientIsAccepted() -> Bool {
        return acceptedSocketDescriptor >= 0
    }

    func disconnect() {
        if clientIsAccepted() {
            close(acceptedSocketDescriptor)
            acceptedSocketDescriptor = -1
        }
    }

    func acceptClientConnection() -> Bool {
        if clientIsAccepted() {
            return true
        }

        acceptedSocketDescriptor = accept(boundSocketDescriptor, nil, nil)
        if (acceptedSocketDescriptor >= 0) {
            print("(mglLocalServer) Accepted a new client connection at path: \(pathToBind)")
            return true
        }

        // Since this is a nonblockign socket, it's OK for accept to return -1 -- as long as errno is EAGAIN or EWOULDBLOCK.
        if (errno != EAGAIN && errno != EWOULDBLOCK) {
            fatalError("(mglLocalServer) Could not accept client connection: \(acceptedSocketDescriptor) errno: \(errno)")
        }
        return false;
    }

    func dataWaiting() -> Bool {
        var pfd = pollfd()
        pfd.fd = acceptedSocketDescriptor;
        pfd.events = Int16(POLLIN);
        pfd.revents = 0;
        _ = withUnsafeMutablePointer(to: &pfd) {
            poll($0, 1, pollMilliseconds)
        }
        return pfd.revents == POLLIN
    }

    func readData(buffer: UnsafeMutableRawPointer, expectedByteCount: Int) -> Int {
        while !dataWaiting() {
            // Keep polling every pollMilliseconds
        }

        let bytesRead = recv(acceptedSocketDescriptor, buffer, expectedByteCount, MSG_WAITALL);
        if bytesRead < 0 {
            print("(mglLocalServer) Error reading \(expectedByteCount) bytes from client: \(bytesRead) errno: \(errno)")
        } else if bytesRead == 0 {
            print("(mglLocalServer) Client disconnected before sending \(expectedByteCount) bytes, disconnecting on this end, too.")
            disconnect()
        }
        return bytesRead
    }

    func sendData(buffer: UnsafeRawPointer, byteCount: Int) -> Int {
        let bytesSent = send(acceptedSocketDescriptor, buffer, byteCount, 0)
        if bytesSent < 0 {
            print("(mglLocalServer) Error sending \(byteCount) bytes to client: \(bytesSent) errno: \(errno)")
        } else if bytesSent != byteCount {
            print("(mglLocalServer) Sent \(bytesSent) to client, but expected to send\(byteCount)")
        }
        return bytesSent
    }

}
