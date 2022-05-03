//
//  mglLocalClient.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 12/9/21.
//  Copyright © 2021 GRU. All rights reserved.
//

import Foundation
import os.log

class mglLocalClient {

    let pollMilliseconds = Int32(10)

    let pathToConnect: String
    var socketDescriptor: Int32

    init(pathToConnect: String) {
        os_log("(mglLocalClient) Starting with path to connect: %{public}@", log: .default, type: .info, String(describing: pathToConnect))
        self.pathToConnect = pathToConnect

        socketDescriptor = socket(AF_UNIX, SOCK_STREAM, 0)
        if socketDescriptor < 0 {
            os_log("(mglLocalClient) Could not create socket, got descriptor: %{public}d, errno %{public}d", log: .default, type: .error, socketDescriptor, errno)
            fatalError("(mglLocalClient) Could not create socket: \(socketDescriptor) errno: \(errno)")
        }

        var address = sockaddr_un()
        address.sun_family = UInt8(AF_UNIX)
        address.sun_len = UInt8(MemoryLayout<sockaddr_un>.size)
        strlcpy(&address.sun_path.0, pathToConnect, MemoryLayout.size(ofValue: address.sun_path))

        // Some interesting swift-c interop here.
        // withUnsafePointer gives us a c-style-pointer to the address struct, which has concrete type sockaddr_un.
        // withMemoryRebound gives is a view of the same pointer, but "cast" to the generic sockaddr type that bind() wants.
        // $0 is an automatic parameter name that can be used in each {} block.
        let addressLength = socklen_t(address.sun_len)
        let connectResult = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(socketDescriptor, $0, addressLength)
            }
        }

        if connectResult < 0 {
            os_log("(mglLocalClient) Could not connect to the path, got result: %{public}d, errno %{public}d", log: .default, type: .error, connectResult, errno)
            fatalError("(mglLocalClient) Could not connect to the path: \(connectResult) errno: \(errno)")
        }

        os_log("(mglLocalClient) Ready and connected to path: %{public}@", log: .default, type: .info, String(describing: pathToConnect))
    }

    deinit {
        disconnect()
    }

    func disconnect() {
        if socketDescriptor != -1 {
            close(socketDescriptor);
            socketDescriptor = -1
        }
    }

    func dataWaiting() -> Bool {
        var pfd = pollfd()
        pfd.fd = socketDescriptor;
        pfd.events = Int16(POLLIN);
        pfd.revents = 0;
        _ = withUnsafeMutablePointer(to: &pfd) {
            poll($0, 1, pollMilliseconds)
        }
        return pfd.revents == POLLIN
    }

    func readData(buffer: UnsafeMutableRawPointer, expectedByteCount: Int) -> Int {
        let bytesRead = recv(socketDescriptor, buffer, expectedByteCount, MSG_WAITALL);
        if bytesRead < 0 {
            os_log("(mglLocalClient) Error reading %{public}d bytes from server, read %{public}d, errno %{public}d", log: .default, type: .error, expectedByteCount, bytesRead, errno)
        } else if bytesRead == 0 {
            os_log("(mglLocalClient) Server disconnected before sending %{public}d bytes, disconnecting this end, too.", log: .default, type: .error, expectedByteCount)
            disconnect()
        }
        return bytesRead
    }

    func sendData(buffer: UnsafeRawPointer, byteCount: Int) -> Int {
        var totalSent = 0
        while totalSent < byteCount {
            let sent = send(socketDescriptor, buffer.advanced(by: totalSent), byteCount - totalSent, 0)
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
            os_log("(mglLocalClient) Error sending %{public}d bytes, sent %{public}d, errno %{public}d", log: .default, type: .error, byteCount, totalSent, errno)
        } else if totalSent != byteCount {
            os_log("(mglLocalClient) Sent %{public}d bytes, but expected to send %{public}d, errno %{public}d", log: .default, type: .error, totalSent, byteCount, errno)
        }
        return totalSent
    }
}
