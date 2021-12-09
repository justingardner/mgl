//
//  mglLocalClient.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 12/9/21.
//  Copyright © 2021 GRU. All rights reserved.
//

import Foundation

class mglLocalClient {

    let pollMilliseconds = Int32(10)

    let pathToConnect: String
    var socketDescriptor: Int32

    init(pathToConnect: String) {
        print("(mglLocalClient) starting with path to connect: \(pathToConnect)")
        self.pathToConnect = pathToConnect

        socketDescriptor = socket(AF_UNIX, SOCK_STREAM, 0)
        if socketDescriptor < 0 {
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
            fatalError("(mglLocalClient) Could not connect to the path: \(connectResult) errno: \(errno)")
        }

        print("(mglLocalClient) ready and connecting to path: \(pathToConnect)")
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
            print("(mglLocalClient) Error reading \(expectedByteCount) bytes from server: \(bytesRead) errno: \(errno)")
        } else if bytesRead == 0 {
            print("(mglLocalClient) Server disconnected before sending \(expectedByteCount) bytes, disconnecting this end, too.")
            disconnect()
        }
        return bytesRead
    }

    func sendData(buffer: UnsafeRawPointer, byteCount: Int) -> Int {
        let bytesSent = send(socketDescriptor, buffer, byteCount, 0)
        if bytesSent < 0 {
            print("(mglLocalClient) Error sending \(byteCount) bytes to client: \(bytesSent) errno: \(errno)")
        } else if bytesSent != byteCount {
            print("(mglLocalClient) Sent \(bytesSent) to client, but expected to send\(byteCount)")
        }
        return bytesSent
    }
}
