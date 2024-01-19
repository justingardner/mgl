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

/*
 The command interface can be in three states, with respect to command batches.
 The command codes startBatch, processBatch, and finishBatch can cycle the command
 interface through these states, in order.
 */
enum BatchState {
    /*
     The default state, "none", is normal operation where commands are processed and
     reported to the client one at a time.
     In this state socket operations and command processing are interleaved.
     */
    case none

    /*
     A "startBatch" command code moves the command interface into the "building" state.
     This state is focused on socket operations but not command processing.
     The client may send multiple commands and these will be fully read as usual,
     then added to the todo queue for later processing.
     For each command received in this state, the command interface will immediately
     report placeholder command results to the client, in order to prevent client
     blocking on each command submitted.
     In this state awaitNext() will never report commands as available.
     */
    case building

    /*
     A "processBatch" command code moves the command interface into the "processing" state.
     This state is focused on command processing but not socket operations.
     In this astate awaitNext() will again expose enqueued todo commands to the renderer,
     allowing the commands to be processed, in the order they arrived, as fast as they can.
     Completed commands will be added to the done queue, for later reporting to the client.
     This keeps the socket quiet during batch processing.

     A "finishBatch" command code moves the command interface back to the "done" state.
     As part of this transition it will report all enqueued done commands to the client
     in the order received and processed.  This reporting will include standard
     timestamps for each command, but not any command-specific query results.
     This keeps the batch results uniform, which should simplify client code for
     handling the batch response.
     */
    case processing
}

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// This class combines an mglServer instance with
// the header mglCommandTypes.h, which is also used
// in our Matlab code, to safely read and write
// supported commands and data types.
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
class mglCommandInterface {
    private let logger: mglLogger

    private let server: mglServer

    // This is used as a queue of commands that have been read fully but not yet processed / rendered.
    private var todo = [mglCommand]()

    // This is used as a queue of commands that have been processed but results not yet reported to the client.
    private var done = [mglCommand]()

    // What state is the command interface in with respect to batches: none, building, or processing?
    private var batchState: BatchState = .none

    // Utility to get system nano time.
    let secs = mglSecs()

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // init
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    init(logger: mglLogger, server: mglServer) {
        self.logger = logger
        self.server = server
    }

    // What is the current batch state -- used from tests.
    func getBatchState() -> BatchState {
        return batchState
    }

    func startBatch() -> mglCommand? {
        self.batchState = .building
        return nil
    }

    func processBatch() -> mglCommand? {
        self.batchState = .processing
        return nil
    }

    func finishBatch() -> mglCommand? {
        writeBatchResults()
        done.removeAll()
        self.batchState = .none
        return nil
    }

    // Wait for the next command from the client, read it fully, and add to the todo queue for processing.
    // Require a MTLDevice so that commands can immediately write data to GPU device buffers, with no intermediate.
    private func awaitCommand(device: MTLDevice) -> mglCommand? {
        // Consume the command code that tells us what to do next.
        // This will block until one arrives.
        guard let commandCode = readCommandCode() else {
            return nil
        }

        // Acknowledge command received.
        let ackTime = secs.get()
        _ = writeDouble(data: ackTime)

        var command: mglCommand? = nil
        switch (commandCode) {
            // Transition batch state but don't initialize a new command -- these return a nil command.
        case mglStartBatch: return startBatch()
        case mglProcessBatch: return processBatch()
        case mglFinishBatch: return finishBatch()

            // Instantiate a new command by reading it fully from the socket.
            // This will block until all command-specific parameters arrive.
        case mglPing: command = mglPingCommand()
        case mglDrainSystemEvents: command = mglDrainSystemEventsCommand()
        case mglFullscreen: command = mglFullscreenCommand()
        case mglWindowed: command = mglWindowedCommand()
        case mglCreateTexture: command = mglCreateTextureCommand(commandInterface: self, device: device)
        case mglReadTexture: command = mglReadTextureCommand(commandInterface: self)
        case mglSetRenderTarget: command = mglSetRenderTargetCommand(commandInterface: self)
        case mglSetWindowFrameInDisplay: command = mglSetWindowFrameInDisplayCommand(commandInterface: self)
        case mglGetWindowFrameInDisplay: command = mglGetWindowFrameInDisplayCommand()
        case mglDeleteTexture: command = mglDeleteTextureCommand(commandInterface: self)
        case mglSetViewColorPixelFormat: command = mglSetViewColorPixelFormatCommand(commandInterface: self)
        case mglStartStencilCreation: command = mglStartStencilCreationCommand(commandInterface: self)
        case mglFinishStencilCreation: command = mglFinishStencilCreationCommand()
        case mglInfo: command = mglInfoCommand()
        case mglGetErrorMessage: command = mglGetErrorMessageCommand()
        case mglFrameGrab: command = mglFrameGrabCommand()
        case mglMinimize: command = mglMinimizeCommand(commandInterface: self)
        case mglDisplayCursor: command = mglDisplayCursorCommand(commandInterface: self)
        case mglFlush: command = mglFlushCommand(commandInterface: self)
        case mglBltTexture: command = mglBltTextureCommand(commandInterface: self, device: device)
        case mglSetXform: command = mglSetXformCommand(commandInterface: self)
        case mglDots: command = mglDotsCommand(commandInterface: self, device: device)
        case mglLine: command = mglLineCommand(commandInterface: self, device: device)
        case mglQuad: command = mglQuadCommand(commandInterface: self, device: device)
        case mglPolygon: command = mglPolygonCommand(commandInterface: self, device: device)
        case mglArcs: command = mglArcsCommand(commandInterface: self, device: device)
        case mglUpdateTexture: command = mglUpdateTextureCommand(commandInterface: self, device: device)
        case mglSelectStencil: command = mglSelectStencilCommand(commandInterface: self)
        case mglSetClearColor: command = mglSetClearColorCommand(commandInterface: self)
        case mglRepeatFlicker: command = mglRepeatFlickerCommand(commandInterface: self)
        case mglRepeatBlts: command = mglRepeatBltsCommand(commandInterface: self)
        case mglRepeatQuads: command = mglRepeatQuadsCommand(commandInterface: self)
        case mglRepeatDots: command = mglRepeatDotsCommand(commandInterface: self)
        case mglRepeatFlush: command = mglRepeatFlushCommand(commandInterface: self)
        default:
            command = nil
        }

        // In case of an unknown command or command init? error,
        // clear out whatever's left on the socket and return to a known, ready state.
        if command == nil {
            clearReadData()
        }

        // Note the command code so we can echo it later.
        command?.results.commandCode = commandCode

        // Note when this command was created.
        command?.results.ackTime = ackTime

        // When building up a batch, unblock the client by sending immediate placeholder results.
        if batchState == .building && command != nil {
            writeResults(command: command!, asPlaceholder: true)
        }

        // We got a whole command, ready to be processed.
        return command
    }

    // Read zero or more available commands from the client into the todo queue.
    // Don't block waiting for commands.
    func readAny(device: MTLDevice) {
        // Give the client a chance to connect.
        if !server.acceptClientConnection() {
            return
        }

        // Keep reading commands as long as data is available.
        while server.dataWaiting() {
            let command = awaitCommand(device: device)
            if command != nil {
                todo.append(command!)
            }
        }
    }

    // Make sure there's a command in the todo queue, blocking and waiting if necessary.
    func awaitNext(device: MTLDevice) {
        if todo.count > 0 {
            return
        }

        let command = awaitCommand(device: device)
        if command != nil {
            todo.append(command!)
        }
    }

    // Get the next command out of the todo queue.
    func next() -> mglCommand? {
        if batchState == BatchState.building {
            return nil
        }

        if todo.count > 0 {
            return todo.removeFirst()
        }
        return nil
    }

    // Collaborate with mglRenderer: this command was fully processed.
    func done(command: mglCommand, success: Bool = true) {
        command.results.success = success
        command.results.processedTime = secs.get()

        if batchState == .processing {
            // When processing a batch, hold done command results for later.
            done.append(command)

            // At the end of the batch, send the client a heads up.
            // This gives the client an event to sync on while waiting for batch completion.
            // This also lets the client know how many command results to expect.
            if todo.isEmpty {
                _ = writeUInt32(data: UInt32(done.count))
            }
        } else {
            // Otherwise, report results immediately.
            writeResults(command: command)
        }
    }

    // Add a command directly to the end of the unprocessed queue -- used during testing.
    func addLast(command: mglCommand) {
        command.results.ackTime = secs.get()
        todo.append(command)
    }

    // Add a command directly to the front of the unprocessed queue -- supports repeated commands.
    func addNext(command: mglCommand) {
        todo.insert(command, at: 0)
    }

    // Report command-specific results and timestamps.
    private func writeResults(command: mglCommand, asPlaceholder: Bool = false) {
        // Write command-specific query results, if any.
        _ = command.writeQueryResults(logger: logger, commandInterface: self)

        // Echo the command code.
        _ = writeCommand(data: command.results.commandCode)

        // Report an explicit status and the processed time,
        // which also represents error status as a negative timestamp.
        if command.results.success || asPlaceholder {
            _ = writeUInt32(data: 1)
            _ = writeDouble(data: command.results.processedTime)
        } else {
            _ = writeUInt32(data: 0)
            logger.error(component: "mglCommandInterface", details: "Command failed: \(String(describing: command))")
            _ = writeDouble(data: -command.results.processedTime)
        }

        // Report additional, detailed timestamps.
        _ = writeDouble(data: command.results.vertexStart)
        _ = writeDouble(data: command.results.vertexEnd)
        _ = writeDouble(data: command.results.fragmentStart)
        _ = writeDouble(data: command.results.fragmentEnd)
        _ = writeDouble(data: command.results.drawableAcquired)
        _ = writeDouble(data: command.results.drawablePresented)
    }

    // Report generic results and timestamps for a command batch.
    // This omits any command-specific query results.
    // This writes one field at a time across all commands,
    // hopefully allowing the client to read in a "vectorized" fashion.
    private func writeBatchResults() {
        // Echo the command codes.
        for command in done { _ = writeCommand(data: command.results.commandCode) }

        // Report explicit statuses.
        for command in done { _ = writeUInt32(data: command.results.success ? 1 : 0) }

        // Report processed times, which also represents error status as negatives.
        for command in done {
            let timestamp = command.results.success ? command.results.processedTime : -command.results.processedTime
            _ = writeDouble(data: timestamp)
        }

        // Report additional, detailed timestamps.
        for command in done { _ = writeDouble(data: command.results.vertexStart) }
        for command in done { _ = writeDouble(data: command.results.vertexEnd) }
        for command in done { _ = writeDouble(data: command.results.fragmentStart) }
        for command in done { _ = writeDouble(data: command.results.fragmentEnd) }
        for command in done { _ = writeDouble(data: command.results.drawableAcquired) }
        for command in done { _ = writeDouble(data: command.results.drawablePresented) }
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // clearReadData
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    private func clearReadData() {
        // declare a byte to dump
        var dumpByte = 0
        var numBytes = 0;
        // while there is data reading
        while server.dataWaiting() {
            // read a byte
            let bytesRead = server.readData(buffer: &dumpByte, expectedByteCount: 1)
            //keep how many bytes we have read
            numBytes = numBytes+bytesRead;
        }
        // display how much data we read.
        logger.info(component: "mglCommandInterface", details: "clearReadData dumped \(numBytes) bytes")
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // readCommand
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func readCommandCode() -> mglCommandCode? {
        var data = mglUnknownCommand
        let expectedByteCount = MemoryLayout<mglCommandCode>.size
        let bytesRead = server.readData(buffer: &data, expectedByteCount: expectedByteCount)
        if (bytesRead != expectedByteCount) {
            logger.error(component: "mglCommandInterface", details: "Expeted to read command code \(expectedByteCount) bytes but read \(bytesRead)")
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
            logger.error(component: "mglCommandInterface", details: "Expeted to read uint32 \(expectedByteCount) bytes but read \(bytesRead)")
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
            logger.error(component: "mglCommandInterface", details: "Expeted to read float \(expectedByteCount) bytes but read \(bytesRead)")
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
            logger.error(component: "mglCommandInterface", details: "Expeted to read rgb color \(expectedByteCount) bytes but read \(bytesRead)")
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
            logger.error(component: "mglCommandInterface", details: "Expeted to read 4x4 float \(expectedByteCount) bytes but read \(bytesRead)")
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
            logger.error(component: "mglCommandInterface", details: "Could not make vertex buffer of size \(expectedByteCount)")
            return nil
        }

        let bytesRead = server.readData(buffer: vertexBuffer.contents(), expectedByteCount: expectedByteCount)
        if (bytesRead != expectedByteCount) {
            logger.error(component: "mglCommandInterface", details: "Expected to read vertex buffer of size \(expectedByteCount) but read \(bytesRead)")
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
            logger.error(component: "mglCommandInterface", details: "Could not make texture buffer of size \(bufferByteSize) image width \(textureWidth) aligned buffer width \(alignedRowByteCount) and image height \(textureHeight)")
            return nil
        }

        // Read from the socket into the texture memory.
        // Copy image rows one at a time, only taking the nominal row size and leaving the rest of the buffer row as padding.
        let bytesRead = imageRowsToBuffer(buffer: textureBuffer, imageRowByteCount: imageRowByteCount, alignedRowByteCount: alignedRowByteCount, rowCount: Int(textureHeight))
        let expectedByteCount = imageRowByteCount * Int(textureHeight)
        if (bytesRead != expectedByteCount) {
            logger.error(component: "mglCommandInterface", details: "Could not read expected bytes \(expectedByteCount) for texture, read \(bytesRead)")
            return nil
        }

        // Now make the buffer into a texture.
        guard let texture = textureBuffer.makeTexture(descriptor: textureDescriptor, offset: 0, bytesPerRow: alignedRowByteCount) else {
            logger.error(component: "mglCommandInterface", details: "Could not make texture from texture buffer of size \(bufferByteSize) image width \(textureWidth) aligned buffer width \(alignedRowByteCount) and image height \(textureHeight)")
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
                logger.error(component: "mglCommandInterface", details: "Expected to read \(imageRowByteCount) bytes but read \(rowBytesRead) for image row \(row) of \(rowCount)")
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
                logger.error(component: "mglCommandInterface", details: "Expected to send \(imageRowByteCount) bytes but read \(rowBytesSent) for image row \(row) of \(rowCount)")
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
