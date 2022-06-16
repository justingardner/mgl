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

    // configuration for doing depth and stencil testing
    var enableDepthAndStencilConfig = [mglDepthStencilConfig]()
    var createStencilConfig = [mglDepthStencilConfig]()
    var createInvertedStencilConfig = [mglDepthStencilConfig]()
    var currentDepthStencilConfig: mglDepthStencilConfig

    // command interface communicates with the client process like Matlab
    let commandInterface : mglCommandInterface
    
    // a flag used to send post-flush acknowledgements back to Matlab
    var acknowledgeFlush = false

    // State to manage commands that repeat themselves over multiple frames/render passes.
    // These drive several different conditionals below that are coupled and need to work in concert.
    // If/when we develop an explicit OOP model for commands,
    // It might be good to refactor these areas using polymorphism, something like the strategy pattern.
    // For example, we might want to have just a currentCommand var here,
    // And then we could move any other state into implementations of mglCommandModel (which is currently just an idea).
    var repeatingCommandCount: UInt32 = 0
    var repeatingCommandCode: mglCommandCode = mglUnknownCommand
    var randomSource: GKRandomSource = GKMersenneTwisterRandomSource(seed: 0)

    // keeps coordinate xform
    var deg2metal = matrix_identity_float4x4

    // a collection of user-managed textures to render to and/or blt to screen
    var textureSequence = UInt32(1)
    var textures : [UInt32: MTLTexture] = [:]

    // pipeline and other configuration to render to the screen or a texture
    var onscreenRenderingConfig: mglColorRenderingConfig
    var currentColorRenderingConfig: mglColorRenderingConfig

    // utility to get system nano time
    let secs = mglSecs()
    
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

        // Set up to enable depth testing and stenciling.
        // Confusingly, some parts of the Metal API treat these as one feature,
        // while other parts treat depth and stenciling as separate features.
        // In this case, the view treates them as one, with one big pixel format (and one buffer/texture) that handles both.
        metalView.depthStencilPixelFormat = .depth32Float_stencil8
        metalView.clearDepth = 1.0

        // Default to depth test enabled, but no stenciling enabled.
        // This currentDepthStencilConfig can be swapped out later to create and select stencils by number.
        for index in 0 ..< 8 {
            enableDepthAndStencilConfig.append(mglEnableDepthAndStencilTest(stencilNumber: UInt32(index), device: device))
            createStencilConfig.append(mglEnableDepthAndStencilCreate(stencilNumber: UInt32(index), isInverted: false, device: device))
            createInvertedStencilConfig.append(mglEnableDepthAndStencilCreate(stencilNumber: UInt32(index), isInverted: true, device: device))
        }
        currentDepthStencilConfig = enableDepthAndStencilConfig[0]

        // Start with default clear color gray, used for on-screen as well as render to texture.
        metalView.clearColor = MTLClearColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)

        // Default to onscreen rendering config.
        guard let onscreenRenderingConfig = mglOnscreenRenderingConfig(device: device, library: library, view: metalView) else {
            fatalError("Could not create onscreen rendering config, got nil!")
        }
        self.onscreenRenderingConfig = onscreenRenderingConfig
        self.currentColorRenderingConfig = onscreenRenderingConfig

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
            acknowledgePreviousCommandProcessed(isSuccess: true)
            acknowledgeFlush = false
        }

        // Do we have a command to process?
        var command: mglCommandCode
        if repeatingCommandCount > 0 {
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
            var commandSuccess = false

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
            default: os_log("(mglRenderer) Unknown non-drawing command code %{public}@", log: .default, type: .error, String(describing: command))
            }

            acknowledgePreviousCommandProcessed(isSuccess: commandSuccess)
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
        if command == mglSetClearColor {
            let commandSuccess = setClearColor(view: view)
            acknowledgePreviousCommandProcessed(isSuccess: commandSuccess)
            if (!commandSuccess) {
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
            os_log("(mglRenderer) Could not get current drawable from the view, skipping render pass.", log: .default, type: .error)
            acknowledgePreviousCommandProcessed(isSuccess: false)
            return
        }

        // This call to getRenderPassDescriptor(view: view) internally calls view.currentRenderPassDescriptor.
        // The call to view.currentRenderPassDescriptor impicitly accessed the view's currentDrawable, as mentioned above.
        // It's possible to swap the order of these calls.
        // But whichever one we call first seems to pay the same blocking/synchronization price when memory usage is high.
        guard let renderPassDescriptor = currentColorRenderingConfig.getRenderPassDescriptor(view: view) else {
            os_log("(mglRenderer) Could not get render pass descriptor from current color rendering config, skipping render pass.", log: .default, type: .error)
            acknowledgePreviousCommandProcessed(isSuccess: false)
            return
        }
        currentDepthStencilConfig.configureRenderPassDescriptor(renderPassDescriptor: renderPassDescriptor)

        guard let commandBuffer = mglRenderer.commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            os_log("(mglRenderer) Could not get command buffer and renderEncoder from the command queue, skipping render pass.", log: .default, type: .error)
            acknowledgePreviousCommandProcessed(isSuccess: false)
            return
        }
        currentDepthStencilConfig.configureRenderEncoder(renderEncoder: renderEncoder)

        // Attach our view transform to the same location expected by all vertex shaders (our convention).
        renderEncoder.setVertexBytes(&deg2metal, length: MemoryLayout<float4x4>.stride, index: 1)

        // Keep processing drawing and other related commands until a flush command.
        while (command != mglFlush) {
            // Clear color is processed as a special case above.
            // All we need to do now is wait for other drawing commands, or a flush command.
            if command == mglSetClearColor {
                command = readAndAcknowledgeNextCommand()
                continue
            }

            // Proces the next drawing command within the current render pass.
            var commandSuccess = false
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
            default: os_log("(mglRenderer) Unknown drawing command code %{public}@", log: .default, type: .error, String(describing: command))
            }

            if !commandSuccess {
                os_log("(mglRenderer) Error processing drawing command %{public}@, abandoning this render pass.", log: .default, type: .error, String(describing: command))
                renderEncoder.endEncoding()
                acknowledgePreviousCommandProcessed(isSuccess: false)
                return
            }

            // We're in a repeating command sequence, so flush to the next frame automatically.
            if repeatingCommandCount > 0 {
                acknowledgeRepeatingCommandAutomaticFlush()
                repeatingCommandCount -= 1
                break
            }

            // Acknowledge this command was processed OK.
            acknowledgePreviousCommandProcessed(isSuccess: true)

            // This will block until the next command arrives.
            // The idea is to process a sequence of drawing commands as fast as we can within a frame.
            command = readAndAcknowledgeNextCommand()
        }

        // If we got here, we just did some drawing, ending with a flush command.
        // We'll wait until the next frame starts before acknowledging that the render pass was fully processed.
        acknowledgeFlush = true

        // Present the drawable, and do other things like synchronize texture buffers, if needed.
        renderEncoder.endEncoding()

        currentColorRenderingConfig.finishDrawing(commandBuffer: commandBuffer, drawable: drawable)
    }

    private func readAndAcknowledgeNextCommand() -> mglCommandCode {
        guard let command = commandInterface.readCommand() else {
            _ = commandInterface.writeDouble(data: -secs.get())
            return mglUnknownCommand
        }
        _ = commandInterface.writeDouble(data: secs.get())
        return command
    }

    private func acknowledgeRepeatingCommandAutomaticFlush() {
        _ = commandInterface.writeDouble(data: secs.get())
    }

    private func acknowledgePreviousCommandProcessed(isSuccess: Bool) {
        if isSuccess {
            _ = commandInterface.writeDouble(data: secs.get())
        } else {
            _ = commandInterface.writeDouble(data: -secs.get())
        }
    }

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

    func setViewColorPixelFormat(view: MTKView) -> Bool {
        guard let formatIndex = commandInterface.readUInt32() else {
            return false
        }

        switch formatIndex {
        case 0: view.colorPixelFormat = .bgra8Unorm
        case 1: view.colorPixelFormat = .bgra8Unorm_srgb
        case 2: view.colorPixelFormat = .rgba16Float
        case 3: view.colorPixelFormat = .rgb10a2Unorm
        case 4: view.colorPixelFormat = .bgr10a2Unorm
        default: view.colorPixelFormat = .bgra8Unorm
        }

        // Recreate the onscreen color rendering config so that render pipelines will use the new color pixel format.
        guard let newOnscreenRenderingConfig = mglOnscreenRenderingConfig(device: mglRenderer.device, library: library, view: view) else {
            os_log("(mglRenderer) Could not create onscreen rendering config for pixel format %{public}@.", log: .default, type: .error, String(describing: view.colorPixelFormat))
            return false
        }

        if (self.currentColorRenderingConfig is mglOnscreenRenderingConfig) {
            // Start using the new config right away!
            self.currentColorRenderingConfig = newOnscreenRenderingConfig
        }

        // Remember the new onscreen config for later, even if we're currently rendering offscreen.
        self.onscreenRenderingConfig = newOnscreenRenderingConfig

        return true
    }

    func drainSystemEvents(view: MTKView) -> Bool {
        guard let window = view.window else {
            os_log("(mglRenderer) Could not get window from view, skipping drain events command.", log: .default, type: .error)
            return false
        }

        var event = window.nextEvent(matching: .any)
        while (event != nil) {
            os_log("(mglRenderer) Processing OS event: %{public}@", log: .default, type: .info, String(describing: event))
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
            os_log("(mglRenderer) Invalid texture number %{public}d, valid numbers are %{public}@.", log: .default, type: .error, String(describing: textures.keys))
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
            currentColorRenderingConfig = onscreenRenderingConfig
            return true
        }

        os_log("(mglRenderer) Got textureNumber %{public}d, choosing offscreen rendering to texture.", log: .default, type: .info, textureNumber)

        guard let newTextureRenderingConfig = mglOffScreenTextureRenderingConfig(device: mglRenderer.device, library: library, view: view, texture: targetTexture) else {
            os_log("(mglRenderer) Could not create offscreen rendering config for textureNumber %{public}d, got nil.", log: .default, type: .error, textureNumber)
            return false
        }
        currentColorRenderingConfig = newTextureRenderingConfig

        return true
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

        let stencilIndex = Array<mglDepthStencilConfig>.Index(stencilNumber)
        if (!createStencilConfig.indices.contains(stencilIndex)) {
            os_log("(mglRenderer) Got stencil number to create %{public}d but only numbers 0-7 are supported.", log: .default, type: .error, stencilNumber)
            return false
        }

        os_log("(mglRenderer) Creating stencil number %{public}d, with isInverted %{public}d.", log: .default, type: .info, stencilNumber, isInverted)
        currentDepthStencilConfig = (isInverted != 0) ? createInvertedStencilConfig[stencilIndex] : createStencilConfig[stencilIndex]
        return true
    }

    func finishStencilCreation(view: MTKView) -> Bool {
        os_log("(mglRenderer) Finishing stencil creation.", log: .default, type: .info)
        currentDepthStencilConfig = enableDepthAndStencilConfig[0]
        return true
    }

    func selectStencil(view: MTKView, renderEncoder: MTLRenderCommandEncoder) -> Bool {
        guard let stencilNumber = commandInterface.readUInt32() else {
            return false
        }

        let stencilIndex = Array<mglDepthStencilConfig>.Index(stencilNumber)
        if (!enableDepthAndStencilConfig.indices.contains(stencilIndex)) {
            os_log("(mglRenderer) Got stencil number to select %{public}d but only numbers 0-7 are supported.", log: .default, type: .error, stencilNumber)
            return false
        }

        os_log("(mglRenderer) Selecting stencil number %{public}d.", log: .default, type: .info, stencilNumber)
        currentDepthStencilConfig = enableDepthAndStencilConfig[stencilIndex]
        currentDepthStencilConfig.configureRenderEncoder(renderEncoder: renderEncoder)
        return true
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

    class func dotsPipelineStateDescriptor(colorPixelFormat:  MTLPixelFormat, depthPixelFormat:  MTLPixelFormat, stencilPixelFormat:  MTLPixelFormat, library: MTLLibrary?) -> MTLRenderPipelineDescriptor {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.depthAttachmentPixelFormat = depthPixelFormat
        pipelineDescriptor.stencilAttachmentPixelFormat = stencilPixelFormat
        pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true;
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperation.add;
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperation.add;
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactor.sourceAlpha;
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactor.sourceAlpha;
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactor.oneMinusSourceAlpha;
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactor.oneMinusSourceAlpha;

        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].offset = 3 * MemoryLayout<Float>.size
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.attributes[2].format = .float2
        vertexDescriptor.attributes[2].offset = 7 * MemoryLayout<Float>.size
        vertexDescriptor.attributes[2].bufferIndex = 0
        vertexDescriptor.attributes[3].format = .float
        vertexDescriptor.attributes[3].offset = 9 * MemoryLayout<Float>.size
        vertexDescriptor.attributes[3].bufferIndex = 0
        vertexDescriptor.attributes[4].format = .float
        vertexDescriptor.attributes[4].offset = 10 * MemoryLayout<Float>.size
        vertexDescriptor.attributes[4].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = 11 * MemoryLayout<Float>.size
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertex_dots")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragment_dots")

        return pipelineDescriptor
    }

    func drawDots(view: MTKView, renderEncoder: MTLRenderCommandEncoder) -> Bool {
        guard let (vertexBufferDots, vertexCount) = commandInterface.readVertices(device: mglRenderer.device, extraVals: 8) else {
            return false
        }

        // Draw all the vertices as points with 11 values per vertex: [xyz rgba wh isRound borderSize].
        renderEncoder.setRenderPipelineState(currentColorRenderingConfig.dotsPipelineState)
        renderEncoder.setVertexBuffer(vertexBufferDots, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertexCount)
        return true
    }

    class func arcsPipelineStateDescriptor(colorPixelFormat:  MTLPixelFormat, depthPixelFormat:  MTLPixelFormat, stencilPixelFormat:  MTLPixelFormat, library: MTLLibrary?) -> MTLRenderPipelineDescriptor {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.depthAttachmentPixelFormat = depthPixelFormat
        pipelineDescriptor.stencilAttachmentPixelFormat = stencilPixelFormat
        pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true;
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperation.add;
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperation.add;
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactor.sourceAlpha;
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactor.sourceAlpha;
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactor.oneMinusSourceAlpha;
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactor.oneMinusSourceAlpha;

        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].offset = 3 * MemoryLayout<Float>.size
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.attributes[2].format = .float2
        vertexDescriptor.attributes[2].offset = 7 * MemoryLayout<Float>.size
        vertexDescriptor.attributes[2].bufferIndex = 0
        vertexDescriptor.attributes[3].format = .float2
        vertexDescriptor.attributes[3].offset = 9 * MemoryLayout<Float>.size
        vertexDescriptor.attributes[3].bufferIndex = 0
        vertexDescriptor.attributes[4].format = .float
        vertexDescriptor.attributes[4].offset = 11 * MemoryLayout<Float>.size
        vertexDescriptor.attributes[4].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = 12 * MemoryLayout<Float>.size
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertex_arcs")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragment_arcs")

        return pipelineDescriptor
    }

    func drawArcs(view: MTKView, renderEncoder: MTLRenderCommandEncoder) -> Bool {
        guard let (vertexBufferDots, vertexCount) = commandInterface.readVertices(device: mglRenderer.device, extraVals: 9) else {
            return false
        }

        // Draw all the vertices as points with 11 values per vertex: [xyz rgba inner outer start sweep].
        renderEncoder.setRenderPipelineState(currentColorRenderingConfig.arcsPipelineState)
        renderEncoder.setVertexBuffer(vertexBufferDots, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertexCount)
        return true
    }

    
    class func bltTexturePipelineStateDescriptor(colorPixelFormat:  MTLPixelFormat, depthPixelFormat:  MTLPixelFormat, stencilPixelFormat:  MTLPixelFormat, library: MTLLibrary?) -> MTLRenderPipelineDescriptor {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.depthAttachmentPixelFormat = depthPixelFormat
        pipelineDescriptor.stencilAttachmentPixelFormat = stencilPixelFormat
        pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true;
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperation.add;
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperation.add;
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactor.sourceAlpha;
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactor.sourceAlpha;
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactor.oneMinusSourceAlpha;
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactor.oneMinusSourceAlpha;

        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = 3 * MemoryLayout<Float>.size
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = 5 * MemoryLayout<Float>.size
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertex_textures")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragment_textures")

        return pipelineDescriptor
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
        renderEncoder.setRenderPipelineState(currentColorRenderingConfig.texturePipelineState)
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

    class func drawVerticesPipelineStateDescriptor(colorPixelFormat:  MTLPixelFormat, depthPixelFormat:  MTLPixelFormat, stencilPixelFormat:  MTLPixelFormat, library: MTLLibrary?) -> MTLRenderPipelineDescriptor {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.depthAttachmentPixelFormat = depthPixelFormat
        pipelineDescriptor.stencilAttachmentPixelFormat = stencilPixelFormat
        pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true;
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperation.add;
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperation.add;
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactor.sourceAlpha;
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactor.sourceAlpha;
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactor.oneMinusSourceAlpha;
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactor.oneMinusSourceAlpha;

        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float3
        vertexDescriptor.attributes[1].offset = 3 * MemoryLayout<Float>.size
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = 6 * MemoryLayout<Float>.size
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertex_with_color")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragment_with_color")

        return pipelineDescriptor
    }

    func drawVerticesWithColor(view: MTKView, renderEncoder: MTLRenderCommandEncoder, primitiveType: MTLPrimitiveType) -> Bool {
        guard let (vertexBufferWithColors, vertexCount) = commandInterface.readVertices(device: mglRenderer.device, extraVals: 3) else {
            return false
        }

        // Render vertices as points with 6 values per vertex: [xyz rgb]
        renderEncoder.setRenderPipelineState(currentColorRenderingConfig.verticesWithColorPipelineState)
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
        if (repeatingCommandCount == 0) {
            guard let repeatCount = commandInterface.readUInt32() else {
                return false
            }
            repeatingCommandCount = UInt32(repeatCount)

            guard let randomSeed = commandInterface.readUInt32() else {
                return false
            }
            randomSource = GKMersenneTwisterRandomSource(seed: UInt64(randomSeed))

            repeatingCommandCode = mglRepeatFlicker
        }

        // Choose a new, random color for the view to use on the next render pass.
        let r = Double(randomSource.nextUniform())
        let g = Double(randomSource.nextUniform())
        let b = Double(randomSource.nextUniform())
        let clearColor = MTLClearColor(red: r, green: g, blue: b, alpha: 1)
        view.clearColor = clearColor

        return true
    }

    func repeatBlts(view: MTKView, renderEncoder: MTLRenderCommandEncoder) -> Bool {
        if (repeatingCommandCount == 0) {
            guard let repeatCount = commandInterface.readUInt32() else {
                return false
            }
            repeatingCommandCount = UInt32(repeatCount)

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
        bufferFloats.assign(from: vertexData, count: vertexData.count)

        // Choose a next texture from the available textures, varying with the repeating command count.
        let textureNumbers = Array(textures.keys).sorted()
        let textureIndex = Int(repeatingCommandCount) % textureNumbers.count
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

        renderEncoder.setRenderPipelineState(currentColorRenderingConfig.texturePipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)
        renderEncoder.setFragmentBytes(&phase, length: MemoryLayout<Float>.stride, index: 2)
        renderEncoder.setFragmentTexture(texture, index:0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)

        return true
    }

}
