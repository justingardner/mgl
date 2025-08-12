//
//  mglSocketServer.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 12/9/21.
//  Copyright © 2021 GRU. All rights reserved.
//

import Foundation

class mglLocalServer : mglServer {
    let logger: mglLogger

    let pathToBind: String
    let maxConnections: Int32
    let pollMilliseconds: Int32

    let boundSocketDescriptor: Int32
    var acceptedSocketDescriptor: Int32 = -1

    init(logger: mglLogger, pathToBind: String, maxConnections: Int32 = Int32(500), pollMilliseconds: Int32 = Int32(10)) {
        self.logger = logger
        self.maxConnections = maxConnections
        self.pollMilliseconds = pollMilliseconds

        logger.info(component: "mglLocalServer", details: "Starting with path to bind: \(pathToBind)")
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

        logger.info(component: "mglLocalServer", details: "Ready and listening for connections at path: \(pathToBind)")
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
            logger.info(component: "mglLocalServer", details: "Accepted a new client connection at path: \(pathToBind)")
            return true
        }

        // Since this is a nonblockign socket, it's OK for accept to return -1 -- as long as errno is EAGAIN or EWOULDBLOCK.
        if (errno != EAGAIN && errno != EWOULDBLOCK) {
            logger.error(component: "mglLocalServer", details: "Could not accept client connection, got result \(acceptedSocketDescriptor), errno \(errno)")
        }
        return false;
    }

    func dataWaiting() -> Bool {
        return dataWaiting(timeout: pollMilliseconds)
    }

    func dataWaiting(timeout: Int32) -> Bool {
        var pfd = pollfd()
        pfd.fd = acceptedSocketDescriptor;
        pfd.events = Int16(POLLIN);
        pfd.revents = 0;
        _ = withUnsafeMutablePointer(to: &pfd) {
            poll($0, 1, timeout)
        }
        return pfd.revents == POLLIN
    }

    func readData(buffer: UnsafeMutableRawPointer, expectedByteCount: Int) -> Int {
        while !dataWaiting() {
            // Keep polling every pollMilliseconds
        }

        var totalRead = 0
        while totalRead < expectedByteCount {
            let bytesRead = recv(acceptedSocketDescriptor, buffer, expectedByteCount, MSG_WAITALL);
            if (bytesRead < 0) {
                if (errno == EAGAIN || errno == EWOULDBLOCK) {
                    continue
                } else {
                    break
                }
            }
            totalRead += bytesRead
        }

        if totalRead < 0 {
            logger.error(component: "mglLocalServer", details: "Error reading \(expectedByteCount) bytes from server, read \(totalRead), errno \(errno)")
        } else if totalRead == 0 {
            logger.error(component: "mglLocalServer", details: "Client disconnected before sending \(expectedByteCount) bytes, disconnecting this end, too.")
            disconnect()
        }
        return totalRead
    }

    func sendData(buffer: UnsafeRawPointer, byteCount: Int) -> Int {
        var totalSent = 0
        while totalSent < byteCount {
            let sent = send(acceptedSocketDescriptor, buffer.advanced(by: totalSent), byteCount - totalSent, 0)
            if (sent < 0) {
                if (errno == EAGAIN || errno == EWOULDBLOCK) {
                    continue
                } else {
                    break
                }
            }
            totalSent += sent
        }
        if totalSent < 0 {
            logger.error(component: "mglLocalServer", details: "Error sending \(byteCount) bytes, sent \(totalSent), errno \(errno)")
        } else if totalSent != byteCount {
            logger.error(component: "mglLocalServer", details: "Sent \(totalSent) bytes, but expected to send \(byteCount), errno \(errno)")
        }
        return totalSent
    }
}
