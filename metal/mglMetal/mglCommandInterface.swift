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
import os.log

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// This class combines an mglServer instance with
// the header mglCommandTypes.h, which is also used
// in our Matlab code, to safely read and write
// supported commands and data types.
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
class mglCommandInterface {
    private let server: mglServer

    // This is used as a queue of commands that have been read fully but not yet processed / rendered.
    private var todo = [mglCommand]()

    // This is used as a queue of commands that have been processed but results not yet sent to the client.
    private var done = [mglCommand]()

    // utility to get system nano time
    let secs = mglSecs()

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // init
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    init(server: mglServer) {
        self.server = server
    }

    // Add a command for processing to the todo queue -- used for testing.
    func addTodo(command: mglCommand) {
        command.results.ackTime = secs.get()
        todo.append(command)
    }

    // Wait for the next command from the client and read it fully before processing.
    // Require a MTLDevice so that we can immediately write data to device buffers, with no intermediate.
    private func awaitCommand(device: MTLDevice) -> mglCommand? {
        // Consume the command code that tells us what to do next.
        // This will block until one arrives.
        guard let commandCode = readCommandCode() else {
            return nil
        }

        // Acknowledge command received.
        // Client should proceed to send command parameters, if any.
        let ackTime = secs.get()
        _ = writeDouble(data: ackTime)

        // Instantiate a new command by reading it fully from the socket.
        // We read the whole command before processing it.
        // This will block until the whole command arrives.
        var command: mglCommand? = nil
        switch (commandCode) {
        case mglPing: command = mglPingCommand()
        case mglDrainSystemEvents: command = mglDrainSystemEventsCommand()
        case mglFullscreen: command = mglFullscreenCommand()
        case mglWindowed: command = mglWindowedCommand()
        case mglCreateTexture: command = mglCreateTextureCommand(commandInterface: self)
        case mglReadTexture: command = mglReadTextureCommand(commandInterface: self)
        case mglSetRenderTarget: command = mglSetRenderTargetCommand(commandInterface: self)
        case mglSetWindowFrameInDisplay: command = mglSetWindowFrameInDisplayCommand(commandInterface: self)
        case mglGetWindowFrameInDisplay: command = mglGetWindowFrameInDisplayCommand()
        case mglDeleteTexture: command = mglDeleteTextureCommand(commandInterface: self)
        case mglSetViewColorPixelFormat: command = mglSetViewColorPixelFormatCommand(commandInterface: self)
        case mglStartStencilCreation: command = mglStartStencilCreationCommand(commandInterface: self)
        case mglFinishStencilCreation: command = mglFinishStencilCreationCommand()
        case mglInfo: command = nil
        case mglGetErrorMessage: command = nil
        case mglFrameGrab: command = nil
        case mglMinimize: command = nil
        case mglDisplayCursor: command = mglDisplayCursorCommand(commandInterface: self)
        case mglFlush: command = mglFlushCommand(commandInterface: self)
        case mglBltTexture: command = nil
        case mglSetXform: command = mglSetXformCommand(commandInterface: self)
        case mglDots: command = nil
        case mglLine: command = nil
        case mglQuad: command = mglQuadCommand(commandInterface: self, device: device)
        case mglPolygon: command = nil
        case mglArcs: command = nil
        case mglUpdateTexture: command = nil
        case mglSelectStencil: command = mglSelectStencilCreationCommand(commandInterface: self)
        case mglSetClearColor: command = mglSetClearColorCommand(commandInterface: self)
        case mglRepeatFlicker: command = nil
        case mglRepeatBlts: command = nil
        case mglRepeatQuads: command = nil
        case mglRepeatDots: command = nil
        case mglRepeatFlush: command = nil
        default:
            command = nil
        }

        // In case of an unknown command or error instantiating a known command,
        // Clear out whatever's left on the socket and return to a known, ready state.
        if command == nil {
            clearReadData()
        }

        // Note when this command was created.
        command?.results.ackTime = ackTime

        // This is a whole command, ready to be processed.
        return command
    }

    // Collaborate with mglRenderer: here's what to render next.
    // TODO: this will change when we're enqueueing a batch.
    func awaitNext(device: MTLDevice) -> mglCommand? {
        if todo.count > 0 {
            return todo.removeFirst()
        }
        return awaitCommand(device: device)
    }

    // Collaborate with mglRenderer: this is done, ready to send results back to the client.
    func done(command: mglCommand) {
        command.results.processedTime = secs.get()
        done.append(command)

        // If we're not still working on a batch, we can send all our results to the client.
        if todo.isEmpty {
            for doneCommand in done {
                _ = doneCommand.writeQueryResults(commandInterface: self)
                if doneCommand.results.success {
                    _ = writeDouble(data: doneCommand.results.processedTime)
                } else {
                    os_log("(mglRenderer) %{public}@ failed", log: .default, type: .error, String(describing: doneCommand))
                    _ = writeDouble(data: -doneCommand.results.processedTime)
                }
            }
            done.removeAll()
        }
    }

    func commandWaiting() -> Bool {
        // Look for commands already in memory, first.
        if !todo.isEmpty {
            return true
        }

        // Give the client a chance to connect, if necessary.
        let clientIsConnected = server.acceptClientConnection()
        if !clientIsConnected {
            return false
        }

        // Check if the client has sent any command bytes yet.
        return server.dataWaiting()
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // acceptClientConnection
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // TODO: remove me
    func acceptClientConnection() -> Bool {
        return server.acceptClientConnection()
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // dataWaiting
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // TODO: remove me
    func dataWaiting() -> Bool {
        return server.dataWaiting()
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // clearReadData
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // TODO: private
    func clearReadData() {
        // declare a byte to dump
        var dumpByte = 0
        var numBytes = 0;
        // while there is data reading
        while dataWaiting() {
            // read a byte
            let bytesRead = server.readData(buffer: &dumpByte, expectedByteCount: 1)
            //keep how many bytes we have read
            numBytes = numBytes+bytesRead;
        }
        // display how much data we read.
        os_log("(mglCommandInterface:clearReadData) Dumped %{public}d bytes", log: .default, type: .info, numBytes);
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // readCommand
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func readCommandCode() -> mglCommandCode? {
        var data = mglUnknownCommand
        let expectedByteCount = MemoryLayout<mglCommandCode>.size
        let bytesRead = server.readData(buffer: &data, expectedByteCount: expectedByteCount)
        if (bytesRead != expectedByteCount) {
            os_log("(mglCommandInterface) Expeted to read command code ${public}d bytes but read %{public}d.", log: .default, type: .error, expectedByteCount, bytesRead)
            return nil
        }
        return data
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // readUINT32
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func readUInt32() -> mglUInt32? {
        var data = mglUInt32(0)
        let expectedByteCount = MemoryLayout<mglUInt32>.size
        let bytesRead = server.readData(buffer: &data, expectedByteCount: expectedByteCount)
        if (bytesRead != expectedByteCount) {
            os_log("(mglCommandInterface) Expeted to read uint32 ${public}d bytes but read %{public}d.", log: .default, type: .error, expectedByteCount, bytesRead)
            return nil
        }
        return data
    }

    func writeUInt32(data: mglUInt32) -> Int {
        var localData = data
        let expectedByteCount = MemoryLayout<mglUInt32>.size
        return server.sendData(buffer: &localData, byteCount: expectedByteCount)
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // readFloat
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func readFloat() -> mglFloat? {
        var data = mglFloat(0)
        let expectedByteCount = MemoryLayout<mglFloat>.size
        let bytesRead = server.readData(buffer: &data, expectedByteCount: expectedByteCount)
        if (bytesRead != expectedByteCount) {
            os_log("(mglCommandInterface) Expeted to read float ${public}d bytes but read %{public}d.", log: .default, type: .error, expectedByteCount, bytesRead)
            return nil
        }
        return data
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // readColor
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func readColor() -> simd_float3? {
        let data = UnsafeMutablePointer<Float>.allocate(capacity: 3)
        defer {
            data.deallocate()
        }

        let expectedByteCount = Int(mglSizeOfFloatRgbColor())
        let bytesRead = server.readData(buffer: data, expectedByteCount: expectedByteCount)
        if (bytesRead != expectedByteCount) {
            os_log("(mglCommandInterface) Expeted to read rgb color ${public}d bytes but read %{public}d.", log: .default, type: .error, expectedByteCount, bytesRead)
            return nil
        }

        // Let the library decide how simd vectors are packed.
        return simd_make_float3(data[0], data[1], data[2])
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // readXform
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func readXform() -> simd_float4x4? {
        let data = UnsafeMutablePointer<Float>.allocate(capacity: 16)
        defer {
            data.deallocate()
        }

        let expectedByteCount = Int(mglSizeOfFloat4x4Matrix())
        let bytesRead = server.readData(buffer: data, expectedByteCount: expectedByteCount)
        if (bytesRead != expectedByteCount) {
            os_log("(mglCommandInterface) Expeted to read 4x4 float ${public}d bytes but read %{public}d.", log: .default, type: .error, expectedByteCount, bytesRead)
            return nil
        }

        // Let the library decide how simd vectors are packed.
        let column0 = simd_make_float4(data[0], data[1], data[2], data[3])
        let column1 = simd_make_float4(data[4], data[5], data[6], data[7])
        let column2 = simd_make_float4(data[8], data[9], data[10], data[11])
        let column3 = simd_make_float4(data[12], data[13], data[14], data[15])
        return(simd_float4x4(column0, column1, column2, column3))
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // readVertices
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func readVertices(device: MTLDevice, extraVals: Int = 0) -> (buffer: MTLBuffer, vertexCount: Int)? {
        guard let vertexCount = readUInt32() else {
            return nil
        }

        // Calculate how many floats we have per vertex.
        // Start with 3 for XYZ, plus extraVals which can be used for things like color channels or texture coordinates.
        let valsPerVertex = mglUInt32(3 + extraVals)
        let expectedByteCount = Int(mglSizeOfFloatVertexArray(vertexCount, valsPerVertex))

        // get an MTLBuffer from the GPU
        // With storageModeManaged, we must explicitly sync the data to the GPU, below.
        guard let vertexBuffer = device.makeBuffer(length: expectedByteCount, options: .storageModeManaged) else {
            os_log("(mglCommandInterface) Could not make vertex buffer of size %{public}d", log: .default, type: .error, expectedByteCount)
            return nil
        }

        let bytesRead = server.readData(buffer: vertexBuffer.contents(), expectedByteCount: expectedByteCount)
        if (bytesRead != expectedByteCount) {
            os_log("(mglCommandInterface) Expected to read vertex buffer of size %{public}d but read %{public}d", log: .default, type: .error, expectedByteCount, bytesRead)
            return nil
        }

        // With storageModeManaged above, we must explicitly sync the new data to the GPU.
        vertexBuffer.didModifyRange( 0 ..< expectedByteCount)
        return (vertexBuffer, Int(vertexCount))
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // readTexture
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func createTexture(device: MTLDevice) -> MTLTexture? {
        guard let textureWidth = readUInt32() else {
            return nil
        }
        guard let textureHeight = readUInt32() else {
            return nil
        }

        // Set the texture descriptor
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba32Float,
            width: Int(textureWidth),
            height: Int(textureHeight),
            mipmapped: false)

        // For now, all textures can receive rendering output.
        textureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]

        // Get the size in bytes of each row of the actual incoming image.
        let imageRowByteCount = Int(mglSizeOfFloatRgbaTexture(mglUInt32(textureWidth), 1))

        // "Round up" this row size to the next multiple of the system-dependent required alignment (perhaps 16 or 256).
        let rowAlignment = device.minimumLinearTextureAlignment(for: textureDescriptor.pixelFormat)
        let alignedRowByteCount = ((imageRowByteCount + rowAlignment - 1) / rowAlignment) * rowAlignment

        // jg: for debugging
        //os_log("(mglCommandInterface:createTexture) minimumLinearTextureAlignment: %{public}d imageRowByteCount: %{public}d alignedRowByteCount: %{public}d", log: .default, type: .info, rowAlignment, imageRowByteCount, alignedRowByteCount)

        // Get an MTLBuffer from the GPU to store image data in
        // Use the rounded-up/aligned row size instead of the nominal image size.
        // With storageModeManaged, we must explicitly sync the data to the GPU, below.
        let bufferByteSize = alignedRowByteCount * Int(textureHeight)
        guard let textureBuffer = device.makeBuffer(length: bufferByteSize, options: .storageModeManaged) else {
            os_log("(mglCommandInterface) Could not make texture buffer of size %{public}d image width %{public}d aligned buffer width %{public}d and image height %{public}d", log: .default, type: .error, bufferByteSize, textureWidth, alignedRowByteCount, textureHeight)
            return nil
        }

        // Read from the socket into the texture memory.
        // Copy image rows one at a time, only taking the nominal row size and leaving the rest of the buffer row as padding.
        let bytesRead = imageRowsToBuffer(buffer: textureBuffer, imageRowByteCount: imageRowByteCount, alignedRowByteCount: alignedRowByteCount, rowCount: Int(textureHeight))
        let expectedByteCount = imageRowByteCount * Int(textureHeight)
        if (bytesRead != expectedByteCount) {
            os_log("(mglCommandInterface) Could not read expected bytes %{public}d for texture, read %{public}d", log: .default, type: .error, expectedByteCount, bytesRead)
            return nil
        }

        // Now make the buffer into a texture.
        guard let texture = textureBuffer.makeTexture(descriptor: textureDescriptor, offset: 0, bytesPerRow: alignedRowByteCount) else {
            os_log("(mglCommandInterface) Could not make texture from texture buffer of size %{public}d image width %{public}d aligned buffer width %{public}d and image height %{public}d", log: .default, type: .error, bufferByteSize, textureWidth, alignedRowByteCount, textureHeight)
            return nil
        }

        return(texture)
    }

    func imageRowsToBuffer(buffer: MTLBuffer, imageRowByteCount: Int, alignedRowByteCount: Int, rowCount: Int) -> Int {
        var imageBytesRead = 0
        for row in 0 ..< rowCount {
            let bufferRow = buffer.contents().advanced(by: row * alignedRowByteCount)
            let rowBytesRead = server.readData(buffer: bufferRow, expectedByteCount: imageRowByteCount)
            if (rowBytesRead != imageRowByteCount) {
                os_log("(mglCommandInterface) Expected to read %{public}d bytes but read %{public}d for image row %{public}d of %{public}d", log: .default, type: .error, imageRowByteCount, rowBytesRead, row, rowCount)
            }
            imageBytesRead += rowBytesRead
        }

        // With storageModeManaged above, we must explicitly sync the new data to the GPU.
        buffer.didModifyRange(0 ..< alignedRowByteCount * rowCount)

        return imageBytesRead
    }

    func imageRowsFromBuffer(buffer: MTLBuffer, imageRowByteCount: Int, alignedRowByteCount: Int, rowCount: Int) -> Int {
        var imageBytesSent = 0
        for row in 0 ..< rowCount {
            let bufferRow = buffer.contents().advanced(by: row * alignedRowByteCount)
            let rowBytesSent = server.sendData(buffer: bufferRow, byteCount: imageRowByteCount)
            if (rowBytesSent != imageRowByteCount) {
                os_log("(mglCommandInterface) Expected to send %{public}d bytes but sent %{public}d for image row %{public}d of %{public}d", log: .default, type: .error, imageRowByteCount, rowBytesSent, row, rowCount)
            }
            imageBytesSent += rowBytesSent
        }
        return imageBytesSent
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // writeDouble
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func writeDouble(data: Double) -> Int {
        var localData = data
        let expectedByteCount = MemoryLayout<mglDouble>.size
        return server.sendData(buffer: &localData, byteCount: expectedByteCount)
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // writeString
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func writeString(data: String) -> Int {
        // send length of string
        var count = UInt16(data.utf16.count)
        var expectedByteCount = MemoryLayout<UInt16>.size
        let bytesSent = server.sendData(buffer: &count, byteCount: expectedByteCount)
        // send the string
        var localData = Array(data.utf16)
        expectedByteCount = data.count * 2
        return bytesSent + server.sendData(buffer: &localData, byteCount: expectedByteCount)
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // writeCommand
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func writeCommand(data: mglCommandCode) -> Int {
        var localData = data
        let expectedByteCount = MemoryLayout<mglCommandCode>.size
        return server.sendData(buffer: &localData, byteCount: expectedByteCount)
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // writeDoubleArray
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func writeDoubleArray(data: Array<Double>) -> Int {
        // send length of string
        var count = UInt32(data.count)
        var expectedByteCount = MemoryLayout<UInt32>.size
        let bytesSent = server.sendData(buffer: &count, byteCount: expectedByteCount)
        // send the array
        var localData = data
        expectedByteCount = data.count * MemoryLayout<Double>.size
        return bytesSent + server.sendData(buffer: &localData, byteCount: expectedByteCount)
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // writeUInt8Array
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func writeUInt8Array(data: Array<UInt8>) -> Int {
        // send length of string
        var count = UInt32(data.count)
        var expectedByteCount = MemoryLayout<UInt32>.size
        let bytesSent = server.sendData(buffer: &count, byteCount: expectedByteCount)
        // send the array
        var localData = data
        expectedByteCount = data.count * MemoryLayout<UInt8>.size
        return bytesSent + server.sendData(buffer: &localData, byteCount: expectedByteCount)
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // writeFloatArray
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func writeFloatArray(data: Array<Float>) -> Int {
        // send length of string
        var count = UInt32(data.count)
        var expectedByteCount = MemoryLayout<UInt32>.size
        let bytesSent = server.sendData(buffer: &count, byteCount: expectedByteCount)
        // send the array
        var localData = data
        expectedByteCount = data.count * MemoryLayout<Float>.size
        return bytesSent + server.sendData(buffer: &localData, byteCount: expectedByteCount)
    }
}
