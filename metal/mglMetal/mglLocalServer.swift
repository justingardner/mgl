//
//  mglSocketServer.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 12/9/21.
//  Copyright © 2021 GRU. All rights reserved.
//

import Foundation
import os.log

class mglLocalServer : mglServer {

    let pathToBind: String
    let maxConnections: Int32 = Int32(500)
    let pollMilliseconds: Int32 = Int32(10)

    let boundSocketDescriptor: Int32
    var acceptedSocketDescriptor: Int32 = -1

    init(pathToBind: String, maxConnections: Int32 = Int32(500), pollMilliseconds: Int32 = Int32(10)) {
        os_log("(mglLocalServer) Starting with path to bind: %{public}@", log: .default, type: .info, String(describing: pathToBind))
        self.pathToBind = pathToBind

        if FileManager.default.fileExists(atPath: pathToBind) {
            let url = URL(fileURLWithPath: pathToBind)
            do {
                try FileManager.default.removeItem(at: url)
            } catch let error as NSError {
                os_log("(mglLocalServer) Unable to remove existing file: %{public}@", log: .default, type: .error, String(describing: pathToBind))
                fatalError("(mglLocalServer) Unable to remove existing file\(pathToBind): \(error)")
            }
        }

        boundSocketDescriptor = socket(AF_UNIX, SOCK_STREAM, 0)
        if boundSocketDescriptor < 0 {
            os_log("(mglLocalServer) Could not create socket, got descriptor: %{public}d, errno %{public}d", log: .default, type: .error, boundSocketDescriptor, errno)
            fatalError("(mglLocalServer) Could not create socket: \(boundSocketDescriptor) errno: \(errno)")
        }

        let nonblockingResult = fcntl(boundSocketDescriptor, F_SETFL, O_NONBLOCK)
        if nonblockingResult < 0 {
            os_log("(mglLocalServer) Could not set socket to nonblocking, got result: %{public}d, errno %{public}d", log: .default, type: .error, nonblockingResult, errno)
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
            os_log("(mglLocalServer) Could not bind the path %{public}@, got result: %{public}d, errno %{public}d", log: .default, type: .error, String(describing: pathToBind), bindResult, errno)
            fatalError("(mglLocalServer) Could not bind the path \(pathToBind) with result: \(bindResult) errno: \(errno)")
        }

        let listenResult = listen(boundSocketDescriptor, maxConnections)
        if listenResult < 0 {
            os_log("(mglLocalServer) Could not listen for connections, got result: %{public}d, errno %{public}d", log: .default, type: .error, listenResult, errno)
            fatalError("(mglLocalServer) Could not listen for connections: \(listenResult) errno: \(errno)")
        }

        os_log("(mglLocalServer) Ready and listening for connections at path: %{public}@", log: .default, type: .info, String(describing: pathToBind))
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
            os_log("(mglLocalServer) Accepted a new client connection at path: %{public}@", log: .default, type: .info, String(describing: pathToBind))
            return true
        }

        // Since this is a nonblockign socket, it's OK for accept to return -1 -- as long as errno is EAGAIN or EWOULDBLOCK.
        if (errno != EAGAIN && errno != EWOULDBLOCK) {
            os_log("(mglLocalServer) Could not accept client connection, got result %{public}d, errno %{public}d", log: .default, type: .info, acceptedSocketDescriptor, errno)
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
            os_log("(mglLocalServer) Error reading %{public}d bytes from server, read %{public}d, errno %{public}d", log: .default, type: .error, expectedByteCount, totalRead, errno)
        } else if totalRead == 0 {
            os_log("(mglLocalServer) Client disconnected before sending %{public}d bytes, disconnecting this end, too.", log: .default, type: .error, expectedByteCount)
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
            os_log("(mglLocalServer) Error sending %{public}d bytes, sent %{public}d, errno %{public}d", log: .default, type: .error, byteCount, totalSent, errno)
        } else if totalSent != byteCount {
            os_log("(mglLocalServer) Sent %{public}d bytes, but expected to send %{public}d, errno %{public}d", log: .default, type: .error, totalSent, byteCount, errno)

        }
        return totalSent
    }

}
