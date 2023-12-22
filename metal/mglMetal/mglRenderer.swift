//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
//
//  mglRenderer.swift
//  mglMetal
//
//  Created by justin gardner on 12/28/2019.
//  Copyright © 2019 GRU. All rights reserved.
//
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Include section
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
import Foundation
import MetalKit
import AppKit
import os.log
import GameplayKit


//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// mglRenderer: Class does most of the work
// handles initializing of the GPU, pipeline states etc
// handles the frame updates and drawing as well as resizing
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
class mglRenderer: NSObject {
    // GPU Device
    static var device : MTLDevice!

    // commandQueue which tells the device what to do
    static var commandQueue: MTLCommandQueue!

    // library holds compiled vertex and fragment shader programs
    let library: MTLLibrary!

    // command interface communicates with the client process like Matlab
    let commandInterface : mglCommandInterface

    // a flag used to send post-flush acknowledgements back to Matlab
    var acknowledgeFlush = false

    // Keep track of depth and stencil state, like creating vs applying a stencil, and which stencil.
    let depthStencilState: mglDepthStencilState

    // Keep track of color rendering state, like oncreen vs offscreen texture, and which texture.
    let colorRenderingState: mglColorRenderingState

    // State to manage commands that repeat themselves over multiple frames/render passes.
    // These drive several different conditionals below that are coupled and need to work in concert.
    // If/when we develop an explicit OOP model for commands,
    // It might be good to refactor these areas using polymorphism, something like the strategy pattern.
    // For example, we might want to have just a currentCommand var here,
    // And then we could move any other state into implementations of mglCommandModel (which is currently just an idea).
    var repeatingCommandFrameCount: UInt32 = 0
    var repeatingCommandCode: mglCommandCode = mglUnknownCommand
    var repeatingCommandRandomSouce: GKRandomSource = GKMersenneTwisterRandomSource(seed: 0)
    var repeatingCommandObjectCount: UInt32 = 0

    // keeps coordinate xform
    var deg2metal = matrix_identity_float4x4

    // a collection of user-managed textures to render to and/or blt to screen
    var textureSequence = UInt32(1)
    var textures : [UInt32: MTLTexture] = [:]

    // utility to get system nano time
    let secs = mglSecs()

    // a string to store the last error message (which can be retrieved via
    // the command mglGetErrorMessage
    var errorMessage = ""

    // flag used in render looop to set whether command has succeeded or not
    var commandSuccess = false

    // flag to keep track of cursor stye
    var cursorHidden = false

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // init
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    init(metalView: MTKView) {
        // bind an address and start listening for client process to connect
        commandInterface = mglCommandInterface()

        // Initialize the GPU device
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("GPU not available")
        }
        metalView.device = device
        mglRenderer.device = device

        // initialize the command queue
        mglRenderer.commandQueue = device.makeCommandQueue()!

        // create a library for storing the shaders
        library = device.makeDefaultLibrary()

        // Inititialize 8 stencil planes and depth testing.
        // Confusingly, some parts of the Metal API treat these as one feature,
        // while other parts treat depth and stenciling as separate features.
        metalView.depthStencilPixelFormat = .depth32Float_stencil8
        metalView.clearDepth = 1.0
        depthStencilState = mglDepthStencilState(device: device)

        // Initialize color rendering, default to onscreen.
        // Default gray clear color applies to onscreen and/or offscreen texture.
        metalView.clearColor = MTLClearColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        colorRenderingState = mglColorRenderingState(device: device, library: library, view: metalView)

        // init the super class
        super.init()

        // Tell the view that this class will be used as the
        // delegate - this makes it so that the view will call
        // the draw function each frame update and the resize function
        metalView.delegate = self

        os_log("(mglRenderer) Init OK.", log: .default, type: .info)
    }
}

extension mglRenderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        os_log("(mglRenderer) drawableSizeWillChange %{public}@", log: .default, type: .info, String(describing: size))
    }

    // We expect the view to be configured for "Timed updates" (the default),
    // which is the traditional way of running once per "video frame", "screen refresh", etc.
    // as described here:
    //   https://developer.apple.com/documentation/metalkit/mtkview?language=objc
    func draw(in view: MTKView) {
        // Using autoreleasepool lets us attempt to release system resources like the "drawable" as soon as we're done.
        // Apple's guidance is to do this once per frame, rather than letting it happen lazily at some later time.
        //  https://developer.apple.com/library/archive/documentation/3DDrawing/Conceptual/MTLBestPracticesGuide/Drawables.html
        autoreleasepool {
            render(in: view)
        }
    }

    // This is the main "loop" for mglMetal.
    // We're currently doing all our app updates here, not just drawing.
    // This includes tasks like:
    //  - accepting pending socket connections from Matlab
    //  - reading comand codes and data from Matlab
    //  - writing command acks and results back to Matlab
    //  - executing non-drawing commands like texture data management, window management, etc.
    //  - executing actual drawing commands!
    private func render(in view: MTKView) {
        // Check if a client connection is already accepted, or try to accept a new one.
        let clientIsConnected = commandInterface.acceptClientConnection()
        if !clientIsConnected {
            // Nothing to do if client isn't connected.  We'll try again on the next draw.
            return
        }

        // Write a post-flush timestamp, which is the command-processed ack for the previous draw.
        if acknowledgeFlush {
            acknowledgePreviousCommandProcessed(isSuccess: true, whichCommand: mglFlush)
            acknowledgeFlush = false
        }

        // Do we have a command to process?
        var command: mglCommandCode
        if repeatingCommandFrameCount > 0 {
            // Yes, were in a repeated command sequence.
            command = repeatingCommandCode
        } else if commandInterface.dataWaiting() {
            // Yes, we have a new command from Matlab.
            command = readAndAcknowledgeNextCommand()
        } else {
            // No, we'll check again on the next frame / draw() call.
            return;
        }

        // Process non-drawing commands one at a time.
        // This avoids holding expensive drawing resources until we need to (below) as described here:
        //   https://developer.apple.com/documentation/quartzcore/cametallayer?language=objc#3385893
        if command.rawValue < mglDrawingCommands.rawValue {
            commandSuccess = false

            switch command {
            case mglPing: commandSuccess = commandInterface.writeCommand(data: mglPing) == mglSizeOfCommandCodeArray(1)
            case mglDrainSystemEvents: commandSuccess = drainSystemEvents(view: view)
            case mglFullscreen: commandSuccess = fullscreen(view: view)
            case mglWindowed: commandSuccess = windowed(view: view)
            case mglCreateTexture: commandSuccess = createTexture()
            case mglReadTexture: commandSuccess = readTexture()
            case mglSetRenderTarget: commandSuccess = setRenderTarget(view: view)
            case mglSetWindowFrameInDisplay: commandSuccess = setWindowFrameInDisplay(view: view)
            case mglGetWindowFrameInDisplay: commandSuccess = getWindowFrameInDisplay(view: view)
            case mglDeleteTexture: commandSuccess = deleteTexture()
            case mglSetViewColorPixelFormat: commandSuccess = setViewColorPixelFormat(view: view)
            case mglStartStencilCreation: commandSuccess = startStencilCreation(view: view)
            case mglFinishStencilCreation: commandSuccess = finishStencilCreation(view: view)
            case mglInfo: commandSuccess = sendAppInfo(view: view)
            case mglGetErrorMessage: commandSuccess = getErrorMessage(view: view)
            case mglFrameGrab: commandSuccess = frameGrab(view: view)
            case mglMinimize: commandSuccess = minimize(view: view)
            case mglDisplayCursor: commandSuccess = displayCursor(view: view)
            default:
                errorMessage = "(mglRenderer) Unknown non-drawing command code \(String(describing: command))"
                os_log("(mglRenderer) Unknown non-drawing command code %{public}@", log: .default, type: .error, String(describing: command))
            }

            acknowledgePreviousCommandProcessed(isSuccess: commandSuccess, whichCommand: command)
            return
        }

        // From here below, we will process the next command as a drawing command.
        // This means setting up a Metal rendering pass and continuing to process commands until an mglFlush command.
        // Or, if there's an error, we'll abandon the rendering pass and return a negative ack.

        // Clear color is a unique case.
        // We need to process it before setting up the rendering pass,
        // so that the frame buffer texture can be cleared to the correct color when it gets loaded at the start of the rendering pass.
        // We don't want to return immediately, as we do with non-drawing commands above, because that incurs a frame wait.
        // Instead we want to fall into the rendering tight loop below.
        // But we don't want to process the clear command along with other drawing commands because by then it's too late
        // the texture will have been loaded and cleared already, using the old clear color.
        // So we process it here in the middle, a special case here.
        var colorHasBeenSet = false
        if command == mglSetClearColor {
            // run setClearColor
            commandSuccess = setClearColor(view: view)
            // keep that the color has been set, since we need
            // that below when we finish the processing of this command
            colorHasBeenSet = true
            if (!commandSuccess) {
                // acknwoledge processing only if this was an error, otherwise
                // wait till we get the drawable before sending sucess
                acknowledgePreviousCommandProcessed(isSuccess: false, whichCommand: command)
                errorMessage = "(mglRenderer) Error setting clear color, skipping render pass."
                os_log("(mglRenderer) Error setting clear color, skipping render pass.", log: .default, type: .error)
                return
            }
        }

        // This call to view.currentDrawable accesses an expensive system resource, the "drawable".
        // Normally this is fast and not a problem.
        // But we've seen it get slow when using large amounts of video memory.
        // For example when we have 30 full-screen-sized textures loaded at once.
        // For rgba Float32 textures, 30 of these can take up about a GB of memory.
        // In this case the call duration is sometimes <1ms, sometimes ~7ms, sometimes even ~14 ms.
        // It's not entirely consistent, but the durations seem to come in runs that last for many frames or several seconds.
        // Even when in a run of ~14ms durations, we don't necessarily drop more frames than usual.
        // When we do drop a frame, this seems to kick off a new run with a different call duration, for a while.
        // We may be seeing some blocking/synchronizing on the expensive "drawable" resource.
        // We seem to be already following the guidance about the "drawable" as discussed in Apple docs:
        //   https://developer.apple.com/documentation/metalkit/mtkview
        //   https://developer.apple.com/documentation/quartzcore/cametallayer#3385893
        //   https://developer.apple.com/library/archive/documentation/3DDrawing/Conceptual/MTLBestPracticesGuide/Drawables.html
        // In particular, we're doing our rendering work inside an autoreleasepool {} block,
        // and we're not acquiring the drawable until we really are about to render a frame.
        // So, are we just finding out how to tax the system and seeing what happens in that case?
        // Does the system "know best" and we are blocking/synchronizing as expected?
        // Or is there somethign else we can do about these long call durations?
        guard let drawable = view.currentDrawable else {
            errorMessage = "(mglRenderer) Could not get current drawable, aborting render pass."
            os_log("(mglRenderer) Could not get current drawable, aborting render pass.", log: .default, type: .error)
            acknowledgePreviousCommandProcessed(isSuccess: false, whichCommand: command)
            return
        }

        // This call to getRenderPassDescriptor(view: view) internally calls view.currentRenderPassDescriptor.
        // The call to view.currentRenderPassDescriptor impicitly accessed the view's currentDrawable, as mentioned above.
        // It's possible to swap the order of these calls.
        // But whichever one we call first seems to pay the same blocking/synchronization price when memory usage is high.
        guard let renderPassDescriptor = colorRenderingState.getRenderPassDescriptor(view: view) else {
            errorMessage = "(mglRenderer) Could not get render pass descriptor from current color rendering config, aborting render pass."
            os_log("(mglRenderer) Could not get render pass descriptor from current color rendering config, aborting render pass.", log: .default, type: .error)
            // we have failed, so return failure to acknwoledge previous command
            acknowledgePreviousCommandProcessed(isSuccess: false, whichCommand: command)
            return
        }
        depthStencilState.configureRenderPassDescriptor(renderPassDescriptor: renderPassDescriptor)

        guard let commandBuffer = mglRenderer.commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            errorMessage = "(mglRenderer) Could not get command buffer and renderEncoder from the command queue, aborting render pass."
            os_log("(mglRenderer) Could not get command buffer and renderEncoder from the command queue, aborting render pass.", log: .default, type: .error)
            acknowledgePreviousCommandProcessed(isSuccess: false, whichCommand: command)
            return
        }
        depthStencilState.configureRenderEncoder(renderEncoder: renderEncoder)

        // Attach our view transform to the same location expected by all vertex shaders (our convention).
        renderEncoder.setVertexBytes(&deg2metal, length: MemoryLayout<float4x4>.stride, index: 1)

        // Keep processing drawing and other related commands until a flush command.
        while (command != mglFlush) {
            // Clear color is processed as a special case above.
            // All we need to do now is wait for other drawing commands, or a flush command.
            if command == mglSetClearColor {
                // if this has been called in the middle of the tight loop,
                // (rather then at the beginning), we will need to read
                // the color and set it, although it won't have any effect
                // until the next frame
                if !colorHasBeenSet {
                    // run setClearColor
                    commandSuccess = setClearColor(view: view)
                }
                // now acknowledge processing
                acknowledgePreviousCommandProcessed(isSuccess: commandSuccess, whichCommand: command)

                // read the next command
                command = readAndAcknowledgeNextCommand()
                // and set that colorHasBeenSet to false (since this
                // is a new command - and if it happens to be a mglClearScreen,
                // then it's color will not have been set.
                colorHasBeenSet = false
                continue
            }

            // Proces the next drawing command within the current render pass.
            commandSuccess = false
            switch command {
            case mglCreateTexture: commandSuccess = createTexture()
            case mglBltTexture: commandSuccess = bltTexture(view: view, renderEncoder: renderEncoder)
            case mglDeleteTexture: commandSuccess = deleteTexture()
            case mglSetXform: commandSuccess = setXform(renderEncoder: renderEncoder)
            case mglDots: commandSuccess = drawDots(view: view, renderEncoder: renderEncoder)
            case mglLine: commandSuccess = drawVerticesWithColor(view: view, renderEncoder: renderEncoder, primitiveType: .line)
            case mglQuad: commandSuccess = drawVerticesWithColor(view: view, renderEncoder: renderEncoder, primitiveType: .triangle)
            case mglPolygon: commandSuccess = drawVerticesWithColor(view: view, renderEncoder: renderEncoder, primitiveType: .triangleStrip)
            case mglArcs: commandSuccess = drawArcs(view: view, renderEncoder: renderEncoder)
            case mglUpdateTexture: commandSuccess = updateTexture()
            case mglSelectStencil: commandSuccess = selectStencil(view: view, renderEncoder: renderEncoder)
            case mglRepeatFlicker: commandSuccess = repeatFlicker(view: view, renderEncoder: renderEncoder)
            case mglRepeatBlts: commandSuccess = repeatBlts(view: view, renderEncoder: renderEncoder)
            case mglRepeatQuads: commandSuccess = repeatQuads(view: view, renderEncoder: renderEncoder)
            case mglRepeatDots: commandSuccess = repeatDots(view: view, renderEncoder: renderEncoder)
            case mglRepeatFlush: commandSuccess = repeatFlush(view: view, renderEncoder: renderEncoder)
            default:
                errorMessage = "(mglRenderer) Unknown drawing command code \(String(describing: command))"
                os_log("(mglRenderer) Unknown drawing command code %{public}@", log: .default, type: .error, String(describing: command))
            }

            if !commandSuccess {
                errorMessage = "(mglRenderer) Error processing drawing command \(String(describing: command)), aborting render pass."
                os_log("(mglRenderer) Error processing drawing command %{public}@, aborting render pass", log: .default, type: .error, String(describing: command))
                acknowledgePreviousCommandProcessed(isSuccess: false, whichCommand: command)
                renderEncoder.endEncoding()
                return
            }

            // We're in a repeating command sequence, so flush to the next frame automatically.
            if repeatingCommandFrameCount > 0 {
                acknowledgeRepeatingCommandAutomaticFlush()
                repeatingCommandFrameCount -= 1
                break
            }

            // Acknowledge this command was processed OK.
            acknowledgePreviousCommandProcessed(isSuccess: true, whichCommand: command)

            // This will block until the next command arrives.
            // The idea is to process a sequence of drawing commands as fast as we can within a frame.
            command = readAndAcknowledgeNextCommand()
        }

        // If we got here, we just did some drawing, ending with a flush command.
        // We'll wait until the next frame starts before acknowledging that the render pass was fully processed.
        acknowledgeFlush = true

        // Present the drawable, and do other things like synchronize texture buffers, if needed.
        renderEncoder.endEncoding()

        colorRenderingState.finishDrawing(commandBuffer: commandBuffer, drawable: drawable)
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // readAndAcknowledgePreviousCommand
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    private func readAndAcknowledgeNextCommand() -> mglCommandCode {
        guard let command = commandInterface.readCommand() else {
            _ = commandInterface.writeDouble(data: -secs.get())
            return mglUnknownCommand
        }
        _ = commandInterface.writeDouble(data: secs.get())
        return command
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // acknowledgeRepeatingCommandAutomaticFlush
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    private func acknowledgeRepeatingCommandAutomaticFlush() {
        _ = commandInterface.writeDouble(data: secs.get())
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // acknowledgePreviousCommandProcessed
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    private func acknowledgePreviousCommandProcessed(isSuccess: Bool, whichCommand: mglCommandCode = mglUnknownCommand) {
        if isSuccess {
            // success send back the time
            _ = commandInterface.writeDouble(data: secs.get())
        } else {
            // log which command failed
            os_log("(mglRenderer) %{public}@ failed", log: .default, type: .error, String(describing: whichCommand))
            // clear any data that a command might have sent
            commandInterface.clearReadData()
            // failure is signaled by negative time.
            _ = commandInterface.writeDouble(data: -secs.get())
        }
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // acknowledgeReturnDataOnItsWay
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    private func acknowledgeReturnDataOnItsWay(isOnItsWay: Bool) {
        if isOnItsWay {
            _ = commandInterface.writeDouble(data: secs.get())
        } else {
            _ = commandInterface.writeDouble(data: -secs.get())
        }
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // Non-drawing commands
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // displayCursor
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    private func displayCursor(view: MTKView) -> Bool {
        // Get whether this is a minimize (0) or restore (1)
        guard let displayOrHide = commandInterface.readUInt32() else {
            return false
        }

        if displayOrHide == 0 {
            // Hide the cursor
            if !self.cursorHidden {
                NSCursor.hide()
                self.cursorHidden = true
            }
        }
        else {
            // Show the cursor
            if self.cursorHidden {
                NSCursor.unhide()
                self.cursorHidden = false
            }

        }
        return true
    }
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // minimize
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    private func minimize(view: MTKView) -> Bool {
        // Get whether this is a minimize (0) or restore (1)
        guard let minimizeOrRestore = commandInterface.readUInt32() else {
            return false
        }

        if minimizeOrRestore == 0 {
            // minimize
            view.window?.miniaturize(nil)
        }
        else {
            // restore
            view.window?.deminiaturize(nil)

        }
        return true
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // frameGrab
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    private func frameGrab(view: MTKView) -> Bool {
        // grab from from the currentColorRenderingTarget. Note that
        // this will return (0,0,nil) if the current target is the screen
        // as it is not implemented (and might be hard/impossible?) to get
        // the bytes from that. So, this only works if the current target
        // is a texture (which is set by mglMetalSetRenderTarget
        let frame = colorRenderingState.frameGrab()
        // write out the width and height
        _ = commandInterface.writeUInt32(data: UInt32(frame.width))
        _ = commandInterface.writeUInt32(data: UInt32(frame.height))
        if frame.pointer != nil {
            // convert the pointer back into an array
            let floatArray = Array(UnsafeBufferPointer(start: frame.pointer, count: frame.width*frame.height*4))
            // write the array
            _ = commandInterface.writeFloatArray(data: floatArray)
            // free the data
            frame.pointer?.deallocate()
            return true
        }
        else {
            return false
        }
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // getErrorMessage
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    private func getErrorMessage(view: MTKView) -> Bool {
        // send error message
        _ = commandInterface.writeString(data: errorMessage)
        return true
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // sendAppInfo
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    private func sendAppInfo(view: MTKView) -> Bool {
        // send GPU name
        _ = commandInterface.writeCommand(data: mglSendString)
        _ = commandInterface.writeString(data: "gpu.name")
        _ = commandInterface.writeCommand(data: mglSendString)
        _ = commandInterface.writeString(data: mglRenderer.device.name)

        // send GPU registryID
        _ = commandInterface.writeCommand(data: mglSendString)
        _ = commandInterface.writeString(data: "gpu.registryID")
        _ = commandInterface.writeCommand(data: mglSendDouble)
        _ = commandInterface.writeDouble(data: Double(mglRenderer.device.registryID))

        // send currentAllocatedSize
        _ = commandInterface.writeCommand(data: mglSendString)
        _ = commandInterface.writeString(data: "gpu.currentAllocatedSize")
        _ = commandInterface.writeCommand(data: mglSendDouble)
        _ = commandInterface.writeDouble(data: Double(mglRenderer.device.currentAllocatedSize))

        // send recommendedMaxWorkingSetSize
        _ = commandInterface.writeCommand(data: mglSendString)
        _ = commandInterface.writeString(data: "gpu.recommendedMaxWorkingSetSize")
        _ = commandInterface.writeCommand(data: mglSendDouble)
        _ = commandInterface.writeDouble(data: Double(mglRenderer.device.recommendedMaxWorkingSetSize))

        // send hasUnifiedMemory
        _ = commandInterface.writeCommand(data: mglSendString)
        _ = commandInterface.writeString(data: "gpu.hasUnifiedMemory")
        _ = commandInterface.writeCommand(data: mglSendDouble)
        _ = commandInterface.writeDouble(data: mglRenderer.device.hasUnifiedMemory ? 1.0 : 0.0)

        // send maxTransferRate
        _ = commandInterface.writeCommand(data: mglSendString)
        _ = commandInterface.writeString(data: "gpu.maxTransferRate")
        _ = commandInterface.writeCommand(data: mglSendDouble)
        _ = commandInterface.writeDouble(data: Double(mglRenderer.device.maxTransferRate))

        // send minimumLinearTextureAlignment
        _ = commandInterface.writeCommand(data: mglSendString)
        _ = commandInterface.writeString(data: "gpu.minimumTextureBufferAlignment")
        _ = commandInterface.writeCommand(data: mglSendDouble)
        _ = commandInterface.writeDouble(data: Double(mglRenderer.device.minimumTextureBufferAlignment(for: .rgba32Float)))

        // send minimumLinearTextureAlignment
        _ = commandInterface.writeCommand(data: mglSendString)
        _ = commandInterface.writeString(data: "gpu.minimumLinearTextureAlignment")
        _ = commandInterface.writeCommand(data: mglSendDouble)
        _ = commandInterface.writeDouble(data: Double(mglRenderer.device.minimumLinearTextureAlignment(for: .rgba32Float)))

        _ = commandInterface.writeCommand(data: mglSendString)
        _ = commandInterface.writeString(data: "view.colorPixelFormat")
        _ = commandInterface.writeCommand(data: mglSendDouble)
        _ = commandInterface.writeDouble(data: Double(view.colorPixelFormat.rawValue))

        _ = commandInterface.writeCommand(data: mglSendString)
        _ = commandInterface.writeString(data: "view.colorPixelFormatString")
        _ = commandInterface.writeCommand(data: mglSendString)
        switch view.colorPixelFormat {
        case MTLPixelFormat.bgra8Unorm: _ = commandInterface.writeString(data: "bgra8Unorm")
        case MTLPixelFormat.bgra8Unorm_srgb: _ = commandInterface.writeString(data: "bgra8Unorm_srgb")
        case MTLPixelFormat.rgba16Float: _ = commandInterface.writeString(data: "rgba16Float")
        case MTLPixelFormat.rgb10a2Unorm: _ = commandInterface.writeString(data: "rgb10a2Unorm")
        case MTLPixelFormat.bgr10a2Unorm: _ = commandInterface.writeString(data: "bgr10a2Unorm")
        default: _ = commandInterface.writeString(data: "Unknown")
        }

        _ = commandInterface.writeCommand(data: mglSendString)
        _ = commandInterface.writeString(data: "view.clearColor")
        _ = commandInterface.writeCommand(data: mglSendDoubleArray)
        let colorArray: [Double] = [Double(view.clearColor.red),Double(view.clearColor.green),Double(view.clearColor.blue),Double(view.clearColor.alpha)]
        _ = commandInterface.writeDoubleArray(data: colorArray)

        _ = commandInterface.writeCommand(data: mglSendString)
        _ = commandInterface.writeString(data: "view.drawableSize")
        _ = commandInterface.writeCommand(data: mglSendDoubleArray)
        let drawableSize: [Double] = [Double(view.drawableSize.width), Double(view.drawableSize.height)]
        _ = commandInterface.writeDoubleArray(data: drawableSize)

        // send finished
        _ = commandInterface.writeCommand(data: mglSendFinished)

        return true
    }

    func setViewColorPixelFormat(view: MTKView) -> Bool {
        guard let formatIndex = commandInterface.readUInt32() else {
            return false
        }

        var format: MTLPixelFormat = .bgra8Unorm
        switch formatIndex {
        case 0: format = .bgra8Unorm
        case 1: format = .bgra8Unorm_srgb
        case 2: format = .rgba16Float
        case 3: format = .rgb10a2Unorm
        case 4: format = .bgr10a2Unorm
        default: format = .bgra8Unorm
        }

        return colorRenderingState.setOnscreenColorPixelFormat(view: view, library: library, pixelFormat: format)
    }

    func drainSystemEvents(view: MTKView) -> Bool {
        guard let window = view.window else {
            os_log("(mglRenderer) Could not get window from view, skipping drain events command.", log: .default, type: .error)
            return false
        }

        var event = window.nextEvent(matching: .any)
        while (event != nil) {
            //os_log("(mglRenderer) Processing OS event: %{public}@", log: .default, type: .info, String(describing: event))
            event = window.nextEvent(matching: .any)
        }

        return true
    }

    func windowed(view: MTKView) -> Bool {
        NSCursor.unhide()

        guard let window = view.window else {
            os_log("(mglRenderer) Could not get window from view, skipping windowed command.", log: .default, type: .error)
            return false
        }

        if !window.styleMask.contains(.fullScreen) {
            os_log("(mglRenderer) App is already windowed, skipping windowed command.", log: .default, type: .info)
        } else {
            window.toggleFullScreen(nil)
        }

        return true
    }

    func setWindowFrameInDisplay(view: MTKView) -> Bool {
        // Read all inputs first.
        guard let displayNumber = commandInterface.readUInt32(),
              let windowX = commandInterface.readUInt32(),
              let windowY = commandInterface.readUInt32(),
              let windowWidth = commandInterface.readUInt32(),
              let windowHeight = commandInterface.readUInt32() else {
            return false
        }

        // Convert Matlab's 1-based display number to a zero-based screen index.
        let screenIndex = displayNumber == 0 ? Array<NSScreen>.Index(0) : Array<NSScreen>.Index(displayNumber - 1)

        // Location of the chosen display AKA screen, according to the system desktop manager.
        // Units might be hi-res "points", convert to native display pixels AKA "backing" as needed.
        let screens = NSScreen.screens
        let screen = screens.indices.contains(screenIndex) ? screens[screenIndex] : screens[0]
        let screenNativeFrame = screen.convertRectToBacking(screen.frame)

        // Location of the window relative to the chosen display, in native pixels
        let x = Int(screenNativeFrame.origin.x) + Int(windowX)
        let y = Int(screenNativeFrame.origin.y) + Int(windowY)
        let windowNativeFrame = NSRect(x: x, y: y, width: Int(windowWidth), height: Int(windowHeight))

        // Location of the window in hi-res "points", or whatever, depending on system config.
        let windowScreenFrame = screen.convertRectFromBacking(windowNativeFrame)

        guard let window = view.window else {
            os_log("(mglRenderer) Could not get window from view, skipping set window frame command.", log: .default, type: .error)
            return false
        }

        if window.styleMask.contains(.fullScreen) {
            os_log("(mglRenderer) App is fullscreen, skipping set window frame command.", log: .default, type: .info)
            return false
        }

        os_log("(mglRenderer) Setting window to display %{public}d frame %{public}@.", log: .default, type: .info, displayNumber, String(describing: windowScreenFrame))
        window.setFrame(windowScreenFrame, display: true)

        return true
    }

    func getWindowFrameInDisplay(view: MTKView) -> Bool {
        guard let window = view.window else {
            os_log("(mglRenderer) Could get window from view, skipping get window frame command.", log: .default, type: .error)
            acknowledgeReturnDataOnItsWay(isOnItsWay: false)
            return false
        }

        guard let screen = window.screen else {
            os_log("(mglRenderer) Could get screen from window, skipping get window frame command.", log: .default, type: .error)
            acknowledgeReturnDataOnItsWay(isOnItsWay: false)
            return false
        }

        guard let screenIndex = NSScreen.screens.firstIndex(of: screen) else {
            os_log("(mglRenderer) Could get screen index from screens, skipping get window frame command.", log: .default, type: .error)
            acknowledgeReturnDataOnItsWay(isOnItsWay: false)
            return false
        }

        // Convert 0-based screen index to Matlab's 1-based display number.
        let displayNumber = mglUInt32(screenIndex + 1)

        // Return the position of the window relative to its screen, in pixel units not hi-res "points".
        let windowNativeFrame = screen.convertRectToBacking(window.frame)
        let screenNativeFrame = screen.convertRectToBacking(screen.frame)
        let windowX = windowNativeFrame.origin.x - screenNativeFrame.origin.x
        let windowY = windowNativeFrame.origin.y - screenNativeFrame.origin.y
        acknowledgeReturnDataOnItsWay(isOnItsWay: true)
        _ = commandInterface.writeUInt32(data: displayNumber)
        _ = commandInterface.writeUInt32(data: mglUInt32(windowX))
        _ = commandInterface.writeUInt32(data: mglUInt32(windowY))
        _ = commandInterface.writeUInt32(data: mglUInt32(windowNativeFrame.width))
        _ = commandInterface.writeUInt32(data: mglUInt32(windowNativeFrame.height))
        return true
    }

    func fullscreen(view: MTKView) -> Bool {
        guard let window = view.window else {
            os_log("(mglRenderer) Could not get window from view, skipping fullscreen command.", log: .default, type: .error)
            return false
        }

        if window.styleMask.contains(.fullScreen) {
            os_log("(mglRenderer) App is already fullscreen, skipping fullscreen command.", log: .default, type: .info)
        } else {
            window.toggleFullScreen(nil)
            NSCursor.hide()
        }

        return true
    }

    func setClearColor(view: MTKView) -> Bool {
        guard let color = commandInterface.readColor() else {
            return false
        }

        view.clearColor = MTLClearColor(red: Double(color[0]), green: Double(color[1]), blue: Double(color[2]), alpha: 1)
        return true
    }

    func createTexture() -> Bool {
        guard let texture = commandInterface.createTexture(device: mglRenderer.device) else {
            return false
        }

        // Consume a texture number from the bookkeeping sequence.
        let newTextureNumber = textureSequence
        textureSequence += 1
        textures[newTextureNumber] = texture

        // Return the new texture's number and the total count of textures.
        acknowledgeReturnDataOnItsWay(isOnItsWay: true)
        _ = commandInterface.writeUInt32(data: newTextureNumber)
        _ = commandInterface.writeUInt32(data: mglUInt32(textures.count))
        return true
    }

    func deleteTexture() -> Bool {
        guard let textureNumber = commandInterface.readUInt32() else {
            return false
        }

        let removed = textures.removeValue(forKey: textureNumber)
        if removed == nil {
            os_log("(mglRenderer) Invalid texture number %{public}d, valid numbers are %{public}@.", log: .default, type: .error, textureNumber, String(describing: textures.keys))
            return false
        }

        os_log("(mglRenderer) Removed texture number %{public}d, remaining numbers are %{public}@.", log: .default, type: .info, textureNumber, String(describing: textures.keys))
        return true
    }

    func setRenderTarget(view: MTKView) -> Bool {
        guard let textureNumber = commandInterface.readUInt32() else {
            return false
        }

        guard let targetTexture = textures[textureNumber] else {
            os_log("(mglRenderer) Got textureNumber %{public}d, choosing onscreen rendering.", log: .default, type: .info, textureNumber)
            return colorRenderingState.setOnscreenRenderingTarget()
        }

        os_log("(mglRenderer) Got textureNumber %{public}d, choosing offscreen rendering to texture.", log: .default, type: .info, textureNumber)
        return colorRenderingState.setRenderTarget(view: view, library: library, targetTexture: targetTexture)
    }

    func readTexture() -> Bool {
        guard let textureNumber = commandInterface.readUInt32() else {
            acknowledgeReturnDataOnItsWay(isOnItsWay: false)
            return false
        }

        guard let texture = textures[textureNumber] else {
            os_log("(mglRenderer) Invalid texture number %{public}d, valid numbers are %{public}@.", log: .default, type: .error, textureNumber, String(describing: textures.keys))
            acknowledgeReturnDataOnItsWay(isOnItsWay: false)
            return false
        }

        guard let buffer = texture.buffer else {
            os_log("(mglCommandInterface) Unable to access buffer of texture %{public}@", log: .default, type: .error, String(describing: texture))
            acknowledgeReturnDataOnItsWay(isOnItsWay: false)
            return false
        }

        let imageRowByteCount = Int(mglSizeOfFloatRgbaTexture(mglUInt32(texture.width), 1))
        acknowledgeReturnDataOnItsWay(isOnItsWay: true)
        _ = commandInterface.writeUInt32(data: mglUInt32(texture.width))
        _ = commandInterface.writeUInt32(data: mglUInt32(texture.height))
        let totalByteCount = commandInterface.imageRowsFromBuffer(buffer: buffer, imageRowByteCount: imageRowByteCount, alignedRowByteCount: texture.bufferBytesPerRow, rowCount: texture.height)

        return totalByteCount == imageRowByteCount * texture.height
    }

    func startStencilCreation(view: MTKView) -> Bool {
        guard let stencilNumber = commandInterface.readUInt32(),
              let isInverted = commandInterface.readUInt32() else {
            return false
        }
        return depthStencilState.startStencilCreation(view: view, stencilNumber: stencilNumber, isInverted: isInverted != 0)
    }

    func finishStencilCreation(view: MTKView) -> Bool {
        return depthStencilState.finishStencilCreation(view: view)
    }

    func selectStencil(view: MTKView, renderEncoder: MTLRenderCommandEncoder) -> Bool {
        guard let stencilNumber = commandInterface.readUInt32() else {
            return false
        }
        return depthStencilState.selectStencil(view: view, renderEncoder: renderEncoder, stencilNumber: stencilNumber)
    }

    func updateTexture() -> Bool {
        guard let textureNumber = commandInterface.readUInt32(),
              let textureWidth = commandInterface.readUInt32(),
              let textureHeight = commandInterface.readUInt32() else {
            return false
        }

        // Resolve the texture and its buffer.
        guard let texture = textures[textureNumber] else {
            os_log("(mglRenderer) Invalid texture number %{public}d, valid numbers are %{public}@.", log: .default, type: .error, textureNumber, String(describing: textures.keys))
            return false
        }

        guard let buffer = texture.buffer else {
            os_log("(mglRenderer) Texture has no buffer to update: %{public}@", log: .default, type: .error, String(describing: texture))
            return false
        }

        // Read the actual image data into the texture.
        let imageRowByteCount = Int(mglSizeOfFloatRgbaTexture(textureWidth, 1))
        let totalByteCount = commandInterface.imageRowsToBuffer(buffer: buffer, imageRowByteCount: imageRowByteCount, alignedRowByteCount: texture.bufferBytesPerRow, rowCount: Int(textureHeight))

        return totalByteCount == imageRowByteCount * Int(textureHeight)
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // Drawing commands
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/

    func drawDots(view: MTKView, renderEncoder: MTLRenderCommandEncoder) -> Bool {
        guard let (vertexBufferDots, vertexCount) = commandInterface.readVertices(device: mglRenderer.device, extraVals: 8) else {
            return false
        }

        // Draw all the vertices as points with 11 values per vertex: [xyz rgba wh isRound borderSize].
        renderEncoder.setRenderPipelineState(colorRenderingState.getDotsPipelineState())
        renderEncoder.setVertexBuffer(vertexBufferDots, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertexCount)
        return true
    }

    func drawArcs(view: MTKView, renderEncoder: MTLRenderCommandEncoder) -> Bool {
        // read the center vertex for the arc from the commandInterface
        // extra values are rgba (1x4), radii (1x4), wedge (1x2), border (1x1)
        guard let (centerVertex, arcCount) = commandInterface.readVertices(device: mglRenderer.device, extraVals: 11) else {
            return false
        }

        // get an MTLBuffer from the GPU for storing the vertices for two triangles (i.e.
        // we are going to make a square around where the arc is going to be drawn, and
        // then color the pixels in the fragment shader according to how far they are away
        // from the center.) Note that the vertices will have 3 + 2 more values than the
        // centerVertex passed in, because each of these vertices will get the xyz of the
        // centerVertex added on (which is used for the calculation for how far away each
        // pixel is from the center in the fragment shader) and the viewport dimensions
        let byteCount = 6 * ((centerVertex.length/arcCount) + 5 * MemoryLayout<Float>.stride);
        guard let triangleVertices = mglRenderer.device.makeBuffer(length: byteCount * arcCount, options: .storageModeManaged) else {
            os_log("(mglRenderer:drawArcs) Could not make vertex buffer of size %{public}d", log: .default, type: .error, byteCount)
            return false
        }

        // get size of buffer as number of floats, note that we add
        // 3 floats for the center position plus 2 floats for the viewport dimensions
        let vertexBufferSize = 5 + (centerVertex.length/arcCount)/MemoryLayout<Float>.stride;

        // get pointers to the buffer that we will pass to the renderer
        let triangleVerticesPointer = triangleVertices.contents().assumingMemoryBound(to: Float.self);

        // get the viewport size, which may be the on-screen view or an offscreen texture
        let (viewportWidth, viewportHeight) = colorRenderingState.getSize(view: view)

        // iterate over how many vertices (i.e. how many arcs) that the user passed in
        for iArc in 0..<arcCount {
            let centerVertexPointer = centerVertex.contents().assumingMemoryBound(to: Float.self) + iArc * (centerVertex.length/arcCount)/MemoryLayout<Float>.stride
            // Now create the vertices of each corner of the triangles by copying
            // the centerVertex in and then modifying the x, y location appropriately
            // get desired x and y locations of the triangle corners
            let x = centerVertexPointer[0];
            let y = centerVertexPointer[1];
            // radius is the outer radius + half the border
            let rX = centerVertexPointer[8]+centerVertexPointer[13]/2;
            let rY = centerVertexPointer[10]+centerVertexPointer[13]/2;
            let xLocs: [Float] = [x-rX, x-rX, x+rX, x-rX, x+rX, x+rX]
            let yLocs: [Float] = [y-rY, y+rY, y+rY, y-rY, y-rY, y+rY]
            
            // iterate over 6 vertices (which will be the corners of the triangles)
            for iVertex in 0...5 {
                // get a pointer to the location in the triangleVertices where we want to copy into
                let thisTriangleVerticesPointer = triangleVerticesPointer + iVertex*vertexBufferSize + iArc*vertexBufferSize*6;
                // and copy the center vertex into each location
                memcpy(thisTriangleVerticesPointer, centerVertexPointer, centerVertex.length/arcCount);
                // now set the xy location
                thisTriangleVerticesPointer[0] = xLocs[iVertex];
                thisTriangleVerticesPointer[1] = yLocs[iVertex];
                // and set the centerVertex
                thisTriangleVerticesPointer[14] = centerVertexPointer[0]
                thisTriangleVerticesPointer[15] = -centerVertexPointer[1]
                thisTriangleVerticesPointer[16] = centerVertexPointer[2]
                // and set viewport dimension
                thisTriangleVerticesPointer[17] = viewportWidth
                thisTriangleVerticesPointer[18] = viewportHeight
            }

        }
        // Draw all the arcs
        renderEncoder.setRenderPipelineState(colorRenderingState.getArcsPipelineState())
        renderEncoder.setVertexBuffer(triangleVertices, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6*arcCount)
        return true
    }

    func bltTexture(view: MTKView, renderEncoder: MTLRenderCommandEncoder) -> Bool {
        // Read all data up front, since it's expected to be consumed.
        guard let minMagFilterRawValue = commandInterface.readUInt32(),
              let mipFilterRawValue = commandInterface.readUInt32(),
              let addressModeRawValue = commandInterface.readUInt32(),
              let (vertexBufferTexture, vertexCount) = commandInterface.readVertices(device: mglRenderer.device, extraVals: 2),
              var phase = commandInterface.readFloat(),
              let textureNumber = commandInterface.readUInt32() else {
            return false
        }

        // Make sure we have the actual requested texture.
        guard let texture = textures[textureNumber] else {
            os_log("(mglRenderer) Invalid texture number %{public}d, valid numbers are %{public}@.", log: .default, type: .error, textureNumber, String(describing: textures.keys))
            return false
        }

        // Set up texture sampling and filtering.
        let minMagFilter = chooseMinMagFilter(rawValue: UInt(minMagFilterRawValue))
        let mipFilter = chooseMipFilter(rawValue: UInt(mipFilterRawValue))
        let addressMode = chooseAddressMode(rawValue: UInt(addressModeRawValue))
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = minMagFilter
        samplerDescriptor.magFilter = minMagFilter
        samplerDescriptor.mipFilter = mipFilter
        samplerDescriptor.sAddressMode = addressMode
        samplerDescriptor.tAddressMode = addressMode
        samplerDescriptor.rAddressMode = addressMode
        let samplerState = mglRenderer.device.makeSamplerState(descriptor:samplerDescriptor)

        // Draw vertices as points with 5 values per vertex: [xyz uv].
        renderEncoder.setRenderPipelineState(colorRenderingState.getTexturePipelineState())
        renderEncoder.setVertexBuffer(vertexBufferTexture, offset: 0, index: 0)
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)
        renderEncoder.setFragmentBytes(&phase, length: MemoryLayout<Float>.stride, index: 2)
        renderEncoder.setFragmentTexture(texture, index:0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)

        return true
    }

    func chooseMinMagFilter(rawValue: UInt, defaultValue: MTLSamplerMinMagFilter = .linear) -> MTLSamplerMinMagFilter {
        guard let filter = MTLSamplerMinMagFilter(rawValue: rawValue) else {
            return defaultValue
        }
        return filter
    }

    func chooseMipFilter(rawValue: UInt, defaultValue: MTLSamplerMipFilter = .linear) -> MTLSamplerMipFilter {
        guard let filter = MTLSamplerMipFilter(rawValue: rawValue) else {
            return defaultValue
        }
        return filter
    }

    func chooseAddressMode(rawValue: UInt, defaultValue: MTLSamplerAddressMode = .repeat) -> MTLSamplerAddressMode {
        guard let filter = MTLSamplerAddressMode(rawValue: rawValue) else {
            return defaultValue
        }
        return filter
    }

    func drawVerticesWithColor(view: MTKView, renderEncoder: MTLRenderCommandEncoder, primitiveType: MTLPrimitiveType) -> Bool {
        guard let (vertexBufferWithColors, vertexCount) = commandInterface.readVertices(device: mglRenderer.device, extraVals: 3) else {
            return false
        }

        // Render vertices as points with 6 values per vertex: [xyz rgb]
        renderEncoder.setRenderPipelineState(colorRenderingState.getVerticesWithColorPipelineState())
        renderEncoder.setVertexBuffer(vertexBufferWithColors, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: primitiveType, vertexStart: 0, vertexCount: vertexCount)
        return true
    }

    func setXform(renderEncoder: MTLRenderCommandEncoder) -> Bool {
        guard let newDeg2Metal = commandInterface.readXform() else {
            return false
        }
        deg2metal = newDeg2Metal

        // Attach this new view transform to the same location expected by all vertex shaders (our convention).
        renderEncoder.setVertexBytes(&deg2metal, length: MemoryLayout<float4x4>.stride, index: 1)
        return true
    }

    func repeatFlicker(view: MTKView, renderEncoder: MTLRenderCommandEncoder) -> Bool {
        if (repeatingCommandFrameCount == 0) {
            guard let repeatCount = commandInterface.readUInt32() else {
                return false
            }
            repeatingCommandFrameCount = UInt32(repeatCount)

            guard let randomSeed = commandInterface.readUInt32() else {
                return false
            }
            repeatingCommandRandomSouce = GKMersenneTwisterRandomSource(seed: UInt64(randomSeed))

            repeatingCommandCode = mglRepeatFlicker
        }

        // Choose a new, random color for the view to use on the next render pass.
        let r = Double(repeatingCommandRandomSouce.nextUniform())
        let g = Double(repeatingCommandRandomSouce.nextUniform())
        let b = Double(repeatingCommandRandomSouce.nextUniform())
        let clearColor = MTLClearColor(red: r, green: g, blue: b, alpha: 1)
        view.clearColor = clearColor

        return true
    }

    func repeatBlts(view: MTKView, renderEncoder: MTLRenderCommandEncoder) -> Bool {
        if (repeatingCommandFrameCount == 0) {
            guard let repeatCount = commandInterface.readUInt32() else {
                return false
            }
            repeatingCommandFrameCount = UInt32(repeatCount)

            repeatingCommandCode = mglRepeatBlts
        }

        // For now, choose arbitrary vertices to blt onto.
        let vertexByteCount = Int(mglSizeOfFloatVertexArray(6, 5))
        guard let vertexBuffer = mglRenderer.device.makeBuffer(length: vertexByteCount, options: .storageModeManaged) else {
            os_log("(mglRenderer) Could not make vertex buffer of size %{public}d", log: .default, type: .error, vertexByteCount)
            return false
        }
        let vertexData: [Float32] = [
            1,  1, 0, 1, 0,
            -1,  1, 0, 0, 0,
            -1, -1, 0, 0, 1,
            1,  1, 0, 1, 0,
            -1, -1, 0, 0, 1,
            1, -1, 0, 1, 1
        ]
        let bufferFloats = vertexBuffer.contents().bindMemory(to: Float32.self, capacity: vertexData.count)
        bufferFloats.update(from: vertexData, count: vertexData.count)

        // Choose a next texture from the available textures, varying with the repeating command count.
        let textureNumbers = Array(textures.keys).sorted()
        let textureIndex = Int(repeatingCommandFrameCount) % textureNumbers.count
        let textureNumber = textureNumbers[textureIndex]
        guard let texture = textures[textureNumber] else {
            os_log("(mglRenderer) Invalid texture number %{public}d, valid numbers are %{public}@.", log: .default, type: .error, textureNumber, String(describing: textures.keys))
            return false
        }

        // For now, choose an arbitrary, fixed sampling strategy.
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .nearest
        samplerDescriptor.magFilter = .nearest
        samplerDescriptor.mipFilter = .nearest
        samplerDescriptor.sAddressMode = .repeat
        samplerDescriptor.tAddressMode = .repeat
        samplerDescriptor.rAddressMode = .repeat
        let samplerState = mglRenderer.device.makeSamplerState(descriptor:samplerDescriptor)

        // For now, assume drift-phase 0.
        var phase = Float32(0)

        renderEncoder.setRenderPipelineState(colorRenderingState.getTexturePipelineState())
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)
        renderEncoder.setFragmentBytes(&phase, length: MemoryLayout<Float>.stride, index: 2)
        renderEncoder.setFragmentTexture(texture, index:0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)

        return true
    }

    func repeatQuads(view: MTKView, renderEncoder: MTLRenderCommandEncoder) -> Bool {
        if (repeatingCommandFrameCount == 0) {
            guard let repeatCount = commandInterface.readUInt32() else {
                return false
            }
            repeatingCommandFrameCount = UInt32(repeatCount)

            guard let objectCount = commandInterface.readUInt32() else {
                return false
            }
            repeatingCommandObjectCount = UInt32(objectCount)

            guard let randomSeed = commandInterface.readUInt32() else {
                return false
            }
            repeatingCommandRandomSouce = GKMersenneTwisterRandomSource(seed: UInt64(randomSeed))

            repeatingCommandCode = mglRepeatQuads
        }

        // Pack a vertex buffer with quads: each has 6 vertices (two triangels) and 6 values per vertex [xyz rgb].
        let vertexCount = Int(6 * repeatingCommandObjectCount)
        let byteCount = Int(mglSizeOfFloatVertexArray(mglUInt32(vertexCount), 6))
        guard let vertexBuffer = mglRenderer.device.makeBuffer(length: byteCount, options: .storageModeManaged) else {
            os_log("(mglRenderer) Could not make vertex buffer of size %{public}d", log: .default, type: .error, byteCount)
            return false
        }
        let bufferFloats = vertexBuffer.contents().bindMemory(to: Float32.self, capacity: vertexCount * 6)
        for quadIndex in (0 ..< repeatingCommandObjectCount) {
            let offset = Int(6 * 6 * quadIndex)
            packRandomQuad(buffer: bufferFloats, offset: offset)
        }

        // The buffer here uses storageModeManaged, to match the behavior of mglCommandInterface.
        // This means we have to tell the GPU about the modifications we just made using the CPU.
        vertexBuffer.didModifyRange(0 ..< byteCount)

        // Render vertices as triangles, two per quad, and 6 values per vertex: [xyz rgb].
        renderEncoder.setRenderPipelineState(colorRenderingState.getVerticesWithColorPipelineState())
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
        return true
    }

    // Create a random quad as the next 6 triangle vertices ([xyz rgb], so 36 elements total) of the given vertex buffer.
    private func packRandomQuad(buffer: UnsafeMutablePointer<Float32>, offset: Int) {
        // Pick four random corners of the quad, vertices 0, 1, 2, 3.
        let x0 = Float32(repeatingCommandRandomSouce.nextUniform() * 2 - 1)
        let x1 = Float32(repeatingCommandRandomSouce.nextUniform() * 2 - 1)
        let x2 = Float32(repeatingCommandRandomSouce.nextUniform() * 2 - 1)
        let x3 = Float32(repeatingCommandRandomSouce.nextUniform() * 2 - 1)
        let y0 = Float32(repeatingCommandRandomSouce.nextUniform() * 2 - 1)
        let y1 = Float32(repeatingCommandRandomSouce.nextUniform() * 2 - 1)
        let y2 = Float32(repeatingCommandRandomSouce.nextUniform() * 2 - 1)
        let y3 = Float32(repeatingCommandRandomSouce.nextUniform() * 2 - 1)

        // Pick one random color for the whole quad.
        let r = Float32(repeatingCommandRandomSouce.nextUniform())
        let g = Float32(repeatingCommandRandomSouce.nextUniform())
        let b = Float32(repeatingCommandRandomSouce.nextUniform())

        // First triangle of the quad gets vertices, 0, 1, 2.
        buffer[offset + 0] = x0
        buffer[offset + 1] = y0
        buffer[offset + 2] = 0
        buffer[offset + 3] = r
        buffer[offset + 4] = g
        buffer[offset + 5] = b
        buffer[offset + 6] = x1
        buffer[offset + 7] = y1
        buffer[offset + 8] = 0
        buffer[offset + 9] = r
        buffer[offset + 10] = g
        buffer[offset + 11] = b
        buffer[offset + 12] = x2
        buffer[offset + 13] = y2
        buffer[offset + 14] = 0
        buffer[offset + 15] = r
        buffer[offset + 16] = g
        buffer[offset + 17] = b

        // Second triangle of the quad gets vertices, 2, 1, 3.
        buffer[offset + 18] = x2
        buffer[offset + 19] = y2
        buffer[offset + 20] = 0
        buffer[offset + 21] = r
        buffer[offset + 22] = g
        buffer[offset + 23] = b
        buffer[offset + 24] = x1
        buffer[offset + 25] = y1
        buffer[offset + 26] = 0
        buffer[offset + 27] = r
        buffer[offset + 28] = g
        buffer[offset + 29] = b
        buffer[offset + 30] = x3
        buffer[offset + 31] = y3
        buffer[offset + 32] = 0
        buffer[offset + 33] = r
        buffer[offset + 34] = g
        buffer[offset + 35] = b
    }

    func repeatDots(view: MTKView, renderEncoder: MTLRenderCommandEncoder) -> Bool {
        if (repeatingCommandFrameCount == 0) {
            guard let repeatCount = commandInterface.readUInt32() else {
                return false
            }
            repeatingCommandFrameCount = UInt32(repeatCount)

            guard let objectCount = commandInterface.readUInt32() else {
                return false
            }
            repeatingCommandObjectCount = UInt32(objectCount)

            guard let randomSeed = commandInterface.readUInt32() else {
                return false
            }
            repeatingCommandRandomSouce = GKMersenneTwisterRandomSource(seed: UInt64(randomSeed))

            repeatingCommandCode = mglRepeatDots
        }

        // Pack a vertex buffer with dots: each has 1 vertex and 11 values per vertex vertex: [xyz rgba wh isRound borderSize].
        let vertexCount = Int(repeatingCommandObjectCount)
        let byteCount = Int(mglSizeOfFloatVertexArray(mglUInt32(vertexCount), 11))
        guard let vertexBuffer = mglRenderer.device.makeBuffer(length: byteCount, options: .storageModeManaged) else {
            os_log("(mglRenderer) Could not make vertex buffer of size %{public}d", log: .default, type: .error, byteCount)
            return false
        }
        let bufferFloats = vertexBuffer.contents().bindMemory(to: Float32.self, capacity: vertexCount)
        for dotIndex in (0 ..< vertexCount) {
            let offset = Int(11 * dotIndex)
            packRandomDot(buffer: bufferFloats, offset: offset)
        }

        // Draw all the vertices as points with 11 values per vertex: [xyz rgba wh isRound borderSize].
        renderEncoder.setRenderPipelineState(colorRenderingState.getDotsPipelineState())
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertexCount)
        return true
    }

    // Create a random dot as the next vertex, with 11 elements per vertex, of the given vertex buffer.
    private func packRandomDot(buffer: UnsafeMutablePointer<Float32>, offset: Int) {
        // xyz
        buffer[offset + 0] = Float32(repeatingCommandRandomSouce.nextUniform() * 2 - 1)
        buffer[offset + 1] = Float32(repeatingCommandRandomSouce.nextUniform() * 2 - 1)
        buffer[offset + 2] = 0

        // rgba
        buffer[offset + 3] = Float32(repeatingCommandRandomSouce.nextUniform())
        buffer[offset + 4] = Float32(repeatingCommandRandomSouce.nextUniform())
        buffer[offset + 5] = Float32(repeatingCommandRandomSouce.nextUniform())
        buffer[offset + 6] = 1

        // wh
        buffer[offset + 7] = 1
        buffer[offset + 8] = 1

        // round
        buffer[offset + 9] = 0

        // border size
        buffer[offset + 10] = 0
    }

    func repeatFlush(view: MTKView, renderEncoder: MTLRenderCommandEncoder) -> Bool {
        if (repeatingCommandFrameCount == 0) {
            guard let repeatCount = commandInterface.readUInt32() else {
                return false
            }
            repeatingCommandFrameCount = UInt32(repeatCount)

            repeatingCommandCode = mglRepeatFlush
        }

        // This is a no-op, the only thing this needed to do was set the repeatingCommandFrameCount, above.
        return true
    }
}
