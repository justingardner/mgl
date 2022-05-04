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

    let library: MTLLibrary!

    // Pipeline states for rendering to screen and texture.
    // These get recreated by setUpPipelines() at init, and when we change the view's colorPixelFormat.
    var pipelineStateDots: MTLRenderPipelineState!
    var pipelineStateDotsToTexture: MTLRenderPipelineState!
    var pipelineStateArcs: MTLRenderPipelineState!
    var pipelineStateArcsToTexture: MTLRenderPipelineState!
    var pipelineStateVertexWithColor: MTLRenderPipelineState!
    var pipelineStateVertexWithColorToTexture: MTLRenderPipelineState!
    var pipelineStateTextures: MTLRenderPipelineState!
    var pipelineStateTexturesToTexture: MTLRenderPipelineState!

    // Configuration for doing depth testing.
    let depthState: MTLDepthStencilState!

    // variable to hold mglCommunicator which
    // communicates with matlab
    let commandInterface : mglCommandInterface
    
    // sets whether to send a flush confirm back to matlab
    var acknowledgeFlush = false

    // keeps coordinate xform
    var deg2metal = matrix_identity_float4x4

    var textureSequence = UInt32(1)
    var textures : [UInt32: MTLTexture] = [:]

    var onscreenRenderingConfig: mglColorRenderingConfig
    var currentColorRenderingConfig: mglColorRenderingConfig

    let secs = mglSecs()
    
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // init
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    init(metalView: MTKView) {
        // init mglCommunicator
        commandInterface = mglCommandInterface()
        
        // Initialize the GPU device
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("GPU not available")
        }
        // tell the view aand renderer about the device
        metalView.device = device
        mglRenderer.device = device

        // initialize the command queue
        mglRenderer.commandQueue = device.makeCommandQueue()!

        // create a library for storing the shaders
        library = device.makeDefaultLibrary()

        // Configure the view to do depth testing.
        metalView.depthStencilPixelFormat = .depth32Float
        metalView.clearDepth = 1.0

        // Configure the depth tests to allow re-drawing when depth (ie z coord) is equal.
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .lessEqual
        depthDescriptor.isDepthWriteEnabled = true
        depthState = device.makeDepthStencilState(descriptor: depthDescriptor)

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

    // This is the main "loop" for mglMetal.
    // We expect the view to be configured for "Timed updates" (the default), as described here:
    // https://developer.apple.com/documentation/metalkit/mtkview?language=objc
    // This the traditional way of running once per "video frame", "screen refresh", etc.
    // We're currently doing all our app updates here, not just drawing.
    // This includes tasks like:
    //  - accepting pending socket connections from Matlab
    //  - reading comand codes and data from Matlab
    //  - writing command acks and results back to Matlab
    //  - executing non-drawing commands like texture data management, window management, etc.
    //  - executing actual drawing commands!
    func draw(in view: MTKView) {
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

        // Check if Matlab sent us a command.
        if !commandInterface.dataWaiting() {
            // Nothing to do until Matlab sends us a command to work on.
            return;
        }

        // We know data is waiting, it should be a command code.
        var command = readAndAcknowledgeNextCommand()

        // Process non-drawing commands one at a time.
        // This avoids holding expensive drawing resources until we need to (below) as described here:
        // https://developer.apple.com/documentation/quartzcore/cametallayer?language=objc#3385893
        if command.rawValue < mglDrawingCommands.rawValue {
            var commandSuccess = false

            switch command {
            case mglPing: commandSuccess = commandInterface.writeCommand(data: mglPing) == mglSizeOfCommandCodeArray(1)
            case mglDrainSystemEvents: commandSuccess = drainSystemEvents(view: view)
            case mglFullscreen: commandSuccess = fullscreen(view: view)
            case mglWindowed: commandSuccess = windowed(view: view)
            case mglSetClearColor: commandSuccess = setClearColor(view: view)
            case mglCreateTexture: commandSuccess = createTexture()
            case mglReadTexture: commandSuccess = readTexture()
            case mglSetRenderTarget: commandSuccess = setRenderTarget(view: view)
            case mglSetWindowFrameInDisplay: commandSuccess = setWindowFrameInDisplay(view: view)
            case mglGetWindowFrameInDisplay: commandSuccess = getWindowFrameInDisplay(view: view)
            case mglDeleteTexture: commandSuccess = deleteTexture()
            case mglSetViewColorPixelFormat: commandSuccess = setViewColorPixelFormat(view: view)
            default: os_log("(mglRenderer) Unknown non-drawing command code %{public}@", log: .default, type: .error, String(describing: command))
            }

            acknowledgePreviousCommandProcessed(isSuccess: commandSuccess)
            return
        }

        // From here below, we will process the next command as a drawing command.
        // This means setting up a rendering pass and continuing to proecess commands until mglFlush.
        // Or, if there's an error, we'll abandon rendering on this frame and return a negative ack.

        // Set up to process one or more drawing commands.
        guard let drawable = view.currentDrawable else {
            os_log("(mglRenderer) Could not get current drawable from the view, skipping render pass.", log: .default, type: .error)
            acknowledgePreviousCommandProcessed(isSuccess: false)
            return
        }

        // Set up a rendering pass, either to texture or to the view's default frame buffer.
        guard let descriptor = currentColorRenderingConfig.getRenderPassDescriptor(view: view) else {
            os_log("(mglRenderer) Could not get render pass descriptor from current color rendering config, skipping render pass.", log: .default, type: .error)
            acknowledgePreviousCommandProcessed(isSuccess: false)
            return
        }

        // Apply the clear color to all rendering passes, before they start.
        descriptor.colorAttachments[0].clearColor = view.clearColor

        guard let commandBuffer = mglRenderer.commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            os_log("(mglRenderer) Could not get command buffer and renderEncoder from the command queue, skipping render pass.", log: .default, type: .error)
            acknowledgePreviousCommandProcessed(isSuccess: false)
            return
        }

        // Enabel depth testing for this render pass.
        renderEncoder.setDepthStencilState(depthState)

        // Attach our view transform to the same location expected by all vertex shaders (our convention).
        renderEncoder.setVertexBytes(&deg2metal, length: MemoryLayout<float4x4>.stride, index: 1)

        // Keep processing drawing and other related commands until a flush command.
        var commandSuccess = false
        while (command != mglFlush) {
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
            default: os_log("(mglRenderer) Unknown drawing command code %{public}@", log: .default, type: .error, String(describing: command))
            }

            // Write a timestamp to Matlab as a command-processed ack.
            acknowledgePreviousCommandProcessed(isSuccess: commandSuccess)

            if !commandSuccess {
                os_log("(mglRenderer) Error processing drawing command %{public}@, abandoning this render pass.", log: .default, type: .error, String(describing: command))
                renderEncoder.endEncoding()
                return
            }

            // This will block until the next command arrives.
            // The idea is to process a sequence of drawing commands as fast as we can.
            command = readAndAcknowledgeNextCommand()
        }

        // If we got here, we just did some drawing, ending with a flush command.
        // We'll acknowledge that the flush command was processed when we get to the start of the next frame, above.
        acknowledgeFlush = true

        // Finished a group of drawing commands, commit the frame and let Metal render it.
        renderEncoder.endEncoding()

        // Present the drawable, and do other things like synchronize texture buffers, if needed.
        currentColorRenderingConfig.finishDrawing(commandBuffer: commandBuffer, drawable: drawable)
    }

    private func readAndAcknowledgeNextCommand() -> mglCommandCode {
        let command = commandInterface.readCommand()
        _ = commandInterface.writeDouble(data: secs.get())
        return command
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
        let formatIndex = commandInterface.readUInt32()

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

        // Remember the new config for later, even if we're currently rendering offscreen.
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
        let displayNumber = commandInterface.readUInt32()
        let windowX = commandInterface.readUInt32()
        let windowY = commandInterface.readUInt32()
        let windowWidth = commandInterface.readUInt32()
        let windowHeight = commandInterface.readUInt32()

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
        let color = commandInterface.readColor()
        view.clearColor = MTLClearColor(red: Double(color[0]), green: Double(color[1]), blue: Double(color[2]), alpha: 1)
        return true
    }

    func createTexture() -> Bool {
        let texture = commandInterface.createTexture(device: mglRenderer.device)

        // Consume a texture number from the sequence.
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
        let textureNumber = commandInterface.readUInt32()

        let removed = textures.removeValue(forKey: textureNumber)
        if removed == nil {
            os_log("(mglRenderer) Invalid texture number %{public}d, valid numbers are %{public}@.", log: .default, type: .error, String(describing: textures.keys))
            return false
        }

        os_log("(mglRenderer) Removed texture number %{public}d, remaining numbers are %{public}@.", log: .default, type: .info, String(describing: textures.keys))
        return true
    }

    func setRenderTarget(view: MTKView) -> Bool {
        let textureNumber = commandInterface.readUInt32()

        guard let targetTexture = textures[textureNumber] else {
            os_log("(mglRenderer) Got textureNumber %{public}d, choosing onscreen rendering.", log: .default, type: .info, textureNumber)
            currentColorRenderingConfig = onscreenRenderingConfig
            return true
        }

        os_log("(mglRenderer) Got textureNumber %{public}d, choosing offscreen rendering to texture.", log: .default, type: .info, textureNumber)

        guard let newTextureRenderingConfig = mglOffScreenTextureRenderingConfig(device: mglRenderer.device, library: library, view: view, texture: targetTexture) else {
            os_log("(mglRenderer) Could not create offscreen rendering config for textureNumber %{public]d, got nil.", log: .default, type: .error, textureNumber)
            return false
        }
        currentColorRenderingConfig = newTextureRenderingConfig
        return true
    }

    func readTexture() -> Bool {
        let textureNumber = commandInterface.readUInt32()

        guard let texture = textures[textureNumber] else {
            os_log("(mglRenderer) Invalid texture number %{public}d, valid numbers are %{public}@.", log: .default, type: .error, String(describing: textures.keys))
            acknowledgeReturnDataOnItsWay(isOnItsWay: false)
            return false
        }

        acknowledgeReturnDataOnItsWay(isOnItsWay: true)
        _ = commandInterface.imageRowsFromTextureBuffer(texture: texture)
        return true
    }

    func updateTexture() -> Bool {
        let textureNumber = commandInterface.readUInt32()
        let textureWidth = commandInterface.readUInt32()
        let textureHeight = Int(commandInterface.readUInt32())

        // Resolve the texture and its buffer.
        guard let texture = textures[textureNumber] else {
            os_log("(mglRenderer) Invalid texture number %{public}d, valid numbers are %{public}@.", log: .default, type: .error, String(describing: textures.keys))
            return false
        }

        guard let buffer = texture.buffer else {
            os_log("(mglRenderer) Texture has no buffer to update: %{public}@", log: .default, type: .error, String(describing: texture))
            return false
        }

        // Read the actual image data into the texture.
        let imageRowByteCount = Int(mglSizeOfFloatRgbaTexture(textureWidth, 1))
        let totalByteCount = commandInterface.imageRowsToBuffer(buffer: buffer, imageRowByteCount: imageRowByteCount, alignedRowByteCount: texture.bufferBytesPerRow, rowCount: textureHeight)
        return totalByteCount == imageRowByteCount * textureHeight
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // Drawing commands
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/

    class func dotsPipelineStateDescriptor(colorPixelFormat:  MTLPixelFormat, depthPixelFormat:  MTLPixelFormat, library: MTLLibrary?) -> MTLRenderPipelineDescriptor {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.depthAttachmentPixelFormat = depthPixelFormat
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
        let (vertexBufferDots, vertexCount) = commandInterface.readVertices(device: mglRenderer.device, extraVals: 8)

        // Draw all the vertices as points with 11 values per vertex: [xyz rgba wh isRound borderSize].
        renderEncoder.setRenderPipelineState(currentColorRenderingConfig.dotsPipelineState)
        renderEncoder.setVertexBuffer(vertexBufferDots, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertexCount)
        return true
    }

    class func arcsPipelineStateDescriptor(colorPixelFormat:  MTLPixelFormat, depthPixelFormat:  MTLPixelFormat, library: MTLLibrary?) -> MTLRenderPipelineDescriptor {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.depthAttachmentPixelFormat = depthPixelFormat
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
        let (vertexBufferDots, vertexCount) = commandInterface.readVertices(device: mglRenderer.device, extraVals: 9)

        // Draw all the vertices as points with 11 values per vertex: [xyz rgba inner outer start sweep].
        renderEncoder.setRenderPipelineState(currentColorRenderingConfig.arcsPipelineState)
        renderEncoder.setVertexBuffer(vertexBufferDots, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertexCount)
        return true
    }

    
    class func bltTexturePipelineStateDescriptor(colorPixelFormat:  MTLPixelFormat, depthPixelFormat:  MTLPixelFormat, library: MTLLibrary?) -> MTLRenderPipelineDescriptor {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.depthAttachmentPixelFormat = depthPixelFormat
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
        // Read all expected data, since it's expected to be consumed.
        let minMagFilterRawValue = commandInterface.readUInt32()
        let mipFilterRawValue = commandInterface.readUInt32()
        let addressModeRawValue = commandInterface.readUInt32()
        let (vertexBufferTexture, vertexCount) = commandInterface.readVertices(device: mglRenderer.device, extraVals: 2)
        var phase = commandInterface.readFloat()
        let textureNumber = commandInterface.readUInt32()

        // Make sure we have the actual requested texture.
        guard let texture = textures[textureNumber] else {
            os_log("(mglRenderer) Invalid texture number %{public}d, valid numbers are %{public}@.", log: .default, type: .error, String(describing: textures.keys))
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

    class func drawVerticesPipelineStateDescriptor(colorPixelFormat:  MTLPixelFormat, depthPixelFormat:  MTLPixelFormat, library: MTLLibrary?) -> MTLRenderPipelineDescriptor {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.depthAttachmentPixelFormat = depthPixelFormat
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
        let (vertexBufferWithColors, vertexCount) = commandInterface.readVertices(device: mglRenderer.device, extraVals: 3)

        // Render vertices as points with 6 values per vertex: [xyz rgb]
        renderEncoder.setRenderPipelineState(currentColorRenderingConfig.verticesWithColorPipelineState)
        renderEncoder.setVertexBuffer(vertexBufferWithColors, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: primitiveType, vertexStart: 0, vertexCount: vertexCount)
        return true
    }

    func setXform(renderEncoder: MTLRenderCommandEncoder) -> Bool {
        deg2metal = commandInterface.readXform();

        // Attach the latest view transform to the same location expected by all vertex shaders (our convention).
        renderEncoder.setVertexBytes(&deg2metal, length: MemoryLayout<float4x4>.stride, index: 1)
        return true
    }
}
