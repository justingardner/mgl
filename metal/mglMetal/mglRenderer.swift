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

    // Pipeline states for rendering to screen
    let pipelineStateDots: MTLRenderPipelineState!
    let pipelineStateArcs: MTLRenderPipelineState!
    let pipelineStateVertexWithColor: MTLRenderPipelineState!
    let pipelineStateTextures: MTLRenderPipelineState!

    // Pipeline states for rendering to texture
    let pipelineStateDotsToTexture: MTLRenderPipelineState!
    let pipelineStateArcsToTexture: MTLRenderPipelineState!
    let pipelineStateVertexWithColorToTexture: MTLRenderPipelineState!
    let pipelineStateTexturesToTexture: MTLRenderPipelineState!

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
    var depthTexture: MTLTexture?

    // What to render into: the number of the texture to render into, otherwise render on-screen.
    var renderTarget = UInt32(0)

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
        let library = device.makeDefaultLibrary()

        // Configure the view to do depth testing.
        metalView.depthStencilPixelFormat = .depth32Float
        metalView.clearDepth = 1.0

        // Create the pipelines that will render to screen or texture.
        // TODO: this looks like a place to factor out common code and do some polymorphism...
        do {
            pipelineStateDots = try device.makeRenderPipelineState(
                descriptor: mglRenderer.dotsPipelineStateDescriptor(
                    colorPixelFormat: metalView.colorPixelFormat,
                    depthPixelFormat: metalView.depthStencilPixelFormat,
                    library: library))
            pipelineStateDotsToTexture = try device.makeRenderPipelineState(
                descriptor: mglRenderer.dotsPipelineStateDescriptor(
                    colorPixelFormat: .rgba32Float,
                    depthPixelFormat: metalView.depthStencilPixelFormat,
                    library: library))

            pipelineStateArcs = try device.makeRenderPipelineState(
                descriptor: mglRenderer.arcsPipelineStateDescriptor(
                    colorPixelFormat: metalView.colorPixelFormat,
                    depthPixelFormat: metalView.depthStencilPixelFormat,
                    library: library))
            pipelineStateArcsToTexture = try device.makeRenderPipelineState(
                descriptor: mglRenderer.arcsPipelineStateDescriptor(
                    colorPixelFormat: .rgba32Float,
                    depthPixelFormat: metalView.depthStencilPixelFormat,
                    library: library))

            pipelineStateVertexWithColor = try device.makeRenderPipelineState(
                descriptor: mglRenderer.drawVerticesPipelineStateDescriptor(
                    colorPixelFormat: metalView.colorPixelFormat,
                    depthPixelFormat: metalView.depthStencilPixelFormat,
                    library: library))
            pipelineStateVertexWithColorToTexture = try device.makeRenderPipelineState(
                descriptor: mglRenderer.drawVerticesPipelineStateDescriptor(
                    colorPixelFormat: .rgba32Float,
                    depthPixelFormat: metalView.depthStencilPixelFormat,
                    library: library))

            pipelineStateTextures = try device.makeRenderPipelineState(
                descriptor: mglRenderer.bltTexturePipelineStateDescriptor(
                    colorPixelFormat: metalView.colorPixelFormat,
                    depthPixelFormat: metalView.depthStencilPixelFormat,
                    library: library))
            pipelineStateTexturesToTexture = try device.makeRenderPipelineState(
                descriptor: mglRenderer.bltTexturePipelineStateDescriptor(
                    colorPixelFormat: .rgba32Float,
                    depthPixelFormat: metalView.depthStencilPixelFormat,
                    library: library))
        } catch let error {
            fatalError(error.localizedDescription)
        }

        // Configure the depth tests to allow re-drawing when depth (ie z coord) is equal.
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .lessEqual
        depthDescriptor.isDepthWriteEnabled = true
        depthState = device.makeDepthStencilState(descriptor: depthDescriptor)

        // Start with default clear color gray, used for on-screen as well as render to texture.
        metalView.clearColor = MTLClearColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)

        // init the super class
        super.init()

        // Tell the view that this class will be used as the
        // delegate - this makes it so that the view will call
        // the draw function each frame update and the resize function
        metalView.delegate = self

        // Done. Print out that we did something.
        print("(mglMetal:mglRenderer) Init mglRenderer")
    }
}

extension mglRenderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        print("(mglRenderer) drawableSizeWillChange \(size)")
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
            _ = commandInterface.writeDouble(data: secs.get())
            acknowledgeFlush = false
        }

        // Check if Matlab sent us a command.
        if !commandInterface.dataWaiting() {
            // Nothing to do until Matlab sends us a command to work on.
            return;
        }

        // Write a timestamp to Matlab as a command-received ack.
        var command = commandInterface.readCommand()
        _ = commandInterface.writeDouble(data: secs.get())

        // Process non-drawing commands one at a time.
        // This avoids holding expensive drawing resources until we need to (below) as described here:
        // https://developer.apple.com/documentation/quartzcore/cametallayer?language=objc#3385893
        if command.rawValue < mglDrawingCommands.rawValue {
            switch command {
            case mglPing: _ = commandInterface.writeCommand(data: mglPing)
            case mglDrainSystemEvents: drainSystemEvents(view: view)
            case mglFullscreen: fullscreen(view: view)
            case mglWindowed: windowed(view: view)
            case mglSetClearColor: setClearColor(view: view)
            case mglCreateTexture: createTexture()
            case mglReadTexture: readTexture()
            case mglSetRenderTarget: setRenderTarget(view: view)
            case mglSetWindowFrameInDisplay: setWindowFrameInDisplay(view: view)
            case mglGetWindowFrameInDisplay: getWindowFrameInDisplay(view: view)
            case mglDeleteTexture: deleteTexture()
            default: print("(mglRenderer) Unknown command code: \(command)")
            }

            // Write a timestamp to Matlab as a command-processed ack.
            _ = commandInterface.writeDouble(data: secs.get())
            return
        }

        // Set up to process one or more drawing commands.
        guard let drawable = view.currentDrawable else {
            // We did nothing, but Matlab still expectes a command-processed ack.
            _ = commandInterface.writeDouble(data: secs.get())
            return
        }

        // Set up a rendering pass, either to texture or to the view's default frame buffer.
        var descriptor: MTLRenderPassDescriptor
        // TODO: lots of places are checking "textures.keys.contains", refactor to be less branch-y.
        if (textures.keys.contains(renderTarget)) {
            // Render to a texture.
            descriptor = MTLRenderPassDescriptor()
            descriptor.colorAttachments[0].texture = textures[renderTarget]
            descriptor.colorAttachments[0].loadAction = .clear
            descriptor.colorAttachments[0].storeAction = .store
            descriptor.depthAttachment.clearDepth = 1.0
            descriptor.depthAttachment.storeAction = .dontCare
            descriptor.depthAttachment.texture = depthTexture
        } else {
            // On-screen rendering as usual.
            guard let currentDescriptor = view.currentRenderPassDescriptor else {
                // We did nothing, but Matlab still expectes a command-processed ack.
                _ = commandInterface.writeDouble(data: secs.get())
                return
            }
            descriptor = currentDescriptor
        }

        // Apply the clear color to all rendering passes, before they start.
        descriptor.colorAttachments[0].clearColor = view.clearColor

        guard let commandBuffer = mglRenderer.commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            // We did nothing, but Matlab still expectes a command-processed ack.
            _ = commandInterface.writeDouble(data: secs.get())
            return
        }

        // Enabel depth testing for this render pass.
        renderEncoder.setDepthStencilState(depthState)

        // Attach our view transform to the same location expected by all vertex shaders (our convention).
        renderEncoder.setVertexBytes(&deg2metal, length: MemoryLayout<float4x4>.stride, index: 1)

        // Keep processing drawing and other related commands until a flush command.
        while (command != mglFlush) {
            switch command {
            case mglCreateTexture: createTexture()
            case mglBltTexture: bltTexture(view: view, renderEncoder: renderEncoder)
            case mglDeleteTexture: deleteTexture()
            case mglSetXform: setXform(renderEncoder: renderEncoder)
            case mglDots: drawDots(view: view, renderEncoder: renderEncoder)
            case mglLine: drawVerticesWithColor(view: view, renderEncoder: renderEncoder, primitiveType: .line)
            case mglQuad: drawVerticesWithColor(view: view, renderEncoder: renderEncoder, primitiveType: .triangle)
            case mglPolygon: drawVerticesWithColor(view: view, renderEncoder: renderEncoder, primitiveType: .triangleStrip)
            case mglArcs: drawArcs(view: view, renderEncoder: renderEncoder)
            case mglUpdateTexture: updateTexture()
            default: print("(mglRenderer) Unknown command code: \(command)")
            }

            // Write a timestamp to Matlab as a command-processed ack.
            _ = commandInterface.writeDouble(data: secs.get())

            // This will block until the next command arrives.
            // The idea is to process a sequence of drawing commands as fast as we can.
            command = commandInterface.readCommand()

            // Write a timestamp to Matlab as a command-received ack.
            _ = commandInterface.writeDouble(data: secs.get())
        }

        // If we got here, we just did some drawing, ending with a flush command.
        // Wait until the next draw, to acknowledge that the flush was processed.
        acknowledgeFlush = true

        // Finished a group of drawing commands, commit the frame and let Metal render it.
        renderEncoder.endEncoding()

        if (textures.keys.contains(renderTarget)) {
            let bltCommandEncoder = commandBuffer.makeBlitCommandEncoder()
            bltCommandEncoder?.synchronize(resource: textures[renderTarget]!)
            bltCommandEncoder?.endEncoding()
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()

        if (textures.keys.contains(renderTarget)) {
            // Wait until the bltCommandEncoder is done syncing data from GPU to CPU.
            commandBuffer.waitUntilCompleted()
        }
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // Non-drawing commands
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/

    func drainSystemEvents(view: MTKView) {
        guard let window = view.window else {return}
        var event = window.nextEvent(matching: .any)
        while (event != nil) {
            print("(mglRenderer) Processing OS event: \(String(describing: event))")
            event = window.nextEvent(matching: .any)
        }
    }

    func windowed(view: MTKView) {
        NSCursor.unhide()

        guard let window = view.window else {
            print("(mglRenderer:windowed) Could not retrieve window")
            return
        }

        if !window.styleMask.contains(.fullScreen) {
            print("(mglRenderer:windowed) Is already windowed")
        } else {
            window.toggleFullScreen(nil)
        }
    }

    func setWindowFrameInDisplay(view: MTKView) {
        // Read from the command interface unconditionally to avoid leaving unused data behind.
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
            print("(mglRenderer:setWindowFrameInDisplay) Could not retrieve window.")
            return
        }

        if window.styleMask.contains(.fullScreen) {
            print("(mglRenderer:setWindowFrameInDisplay) Skipping, since window is in fullscreen.")
            return
        }

        print("(mglRenderer:setWindowFrameInDisplay) Setting window to display \(displayNumber) frame \(windowScreenFrame).")
        window.setFrame(windowScreenFrame, display: true)
    }

    func getWindowFrameInDisplay(view: MTKView) {
        guard let window = view.window else {
            print("(mglRenderer:getWindowFrameInDisplay) Could not retrieve window from view.")
            _ = commandInterface.writeUInt32(data: mglUInt32(0))
            _ = commandInterface.writeUInt32(data: mglUInt32(0))
            _ = commandInterface.writeUInt32(data: mglUInt32(0))
            _ = commandInterface.writeUInt32(data: mglUInt32(0))
            _ = commandInterface.writeUInt32(data: mglUInt32(0))
            return
        }

        guard let screen = window.screen else {
            print("(mglRenderer:getWindowFrameInDisplay) Could not retrieve screen from window.")
            _ = commandInterface.writeUInt32(data: mglUInt32(0))
            _ = commandInterface.writeUInt32(data: mglUInt32(0))
            _ = commandInterface.writeUInt32(data: mglUInt32(0))
            _ = commandInterface.writeUInt32(data: mglUInt32(0))
            _ = commandInterface.writeUInt32(data: mglUInt32(0))
            return
        }

        guard let screenIndex = NSScreen.screens.firstIndex(of: screen) else {
            print("(mglRenderer:getWindowFrameInDisplay) Could not retrieve screen index from screens.")
            _ = commandInterface.writeUInt32(data: mglUInt32(0))
            _ = commandInterface.writeUInt32(data: mglUInt32(0))
            _ = commandInterface.writeUInt32(data: mglUInt32(0))
            _ = commandInterface.writeUInt32(data: mglUInt32(0))
            _ = commandInterface.writeUInt32(data: mglUInt32(0))
            return
        }

        // Convert 0-based screen index to Matlab's 1-based display number.
        let displayNumber = mglUInt32(screenIndex + 1)

        // Return the position of the window relative to its screen, in pixel units not hi-res "points".
        let windowNativeFrame = screen.convertRectToBacking(window.frame)
        let screenNativeFrame = screen.convertRectToBacking(screen.frame)
        let windowX = windowNativeFrame.origin.x - screenNativeFrame.origin.x
        let windowY = windowNativeFrame.origin.y - screenNativeFrame.origin.y
        _ = commandInterface.writeUInt32(data: displayNumber)
        _ = commandInterface.writeUInt32(data: mglUInt32(windowX))
        _ = commandInterface.writeUInt32(data: mglUInt32(windowY))
        _ = commandInterface.writeUInt32(data: mglUInt32(windowNativeFrame.width))
        _ = commandInterface.writeUInt32(data: mglUInt32(windowNativeFrame.height))
    }

    func fullscreen(view: MTKView) {
        guard let window = view.window else {
            print("(mglRenderer:fullscreen) Could not retrieve window")
            return
        }
        if window.styleMask.contains(.fullScreen) {
            print("(mglRenderer:fullscreen) Is already full screen")
        } else {
            window.toggleFullScreen(nil)
            NSCursor.hide()
        }
    }

    func setClearColor(view: MTKView) {
        let color = commandInterface.readColor()
        view.clearColor = MTLClearColor(red: Double(color[0]), green: Double(color[1]), blue: Double(color[2]), alpha: 1)
    }

    func createTexture() {
        let texture = commandInterface.createTexture(device: mglRenderer.device)
        textures[textureSequence] = texture

        // Return the new texture's number and the total count of textures.
        _ = commandInterface.writeUInt32(data: textureSequence)
        _ = commandInterface.writeUInt32(data: mglUInt32(textures.count))

        // Consume a texture number from the sequence.
        textureSequence += 1
    }

    func deleteTexture() {
        let textureNumber = commandInterface.readUInt32()
        let removed = textures.removeValue(forKey: textureNumber)
        if removed == nil {
            print("(mglRenderer:deleteTexture) invalid textureNumber \(textureNumber), valid numbers are \(textures.keys)")
        } else {
            print("(mglRenderer:deleteTexture) removed textureNumber \(textureNumber), remaining numbers are \(textures.keys)")
        }
    }

    func setRenderTarget(view: MTKView) {
        renderTarget = commandInterface.readUInt32()
        ensureMatchingDepthDexture(view: view)
    }

    func ensureMatchingDepthDexture(view: MTKView) {
        guard let targetTexture = textures[renderTarget] else {
            print("(mglRenderer:ensureMatchingDepthDexture) invalid renderTarget \(renderTarget), valid targets are \(textures.keys)")
            return
        }

        guard let depthTextureNotNull = depthTexture else {
            print("(mglRenderer:ensureMatchingDepthDexture) creating new depth texture because we don't have one yet.")
            depthTexture = createMatchingDepthTexture(texture: targetTexture, view: view)
            return
        }

        if (depthTextureNotNull.width != targetTexture.width || depthTextureNotNull.height != targetTexture.height) {
            print("(mglRenderer:ensureMatchingDepthDexture) replacing old depth texture (\(depthTextureNotNull.width) x \(depthTextureNotNull.height)) because it doesn't match the current render target size (\(targetTexture.width) x \(targetTexture.height)).")
            depthTexture = createMatchingDepthTexture(texture: targetTexture, view: view)
        }
    }

    func createMatchingDepthTexture(texture: MTLTexture, view: MTKView) -> MTLTexture {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: view.depthStencilPixelFormat,
            width: texture.width, height: texture.height, mipmapped: false)
        descriptor.storageMode = .private
        descriptor.usage = .renderTarget
        return mglRenderer.device.makeTexture(descriptor: descriptor)!
    }

    func readTexture() {
        let textureNumber = commandInterface.readUInt32()
        guard let texture = textures[textureNumber] else {
            print("(mglRenderer:readTexture) invalid textureNumber \(textureNumber), valid numbers are \(textures.keys)")
            // No data to return, but Matlab expects a response wiht width and height.
            _ = commandInterface.writeUInt32(data: 0)
            _ = commandInterface.writeUInt32(data: 0)
            return;
        }
        _ = commandInterface.writeTexture(texture: texture)
    }

    func updateTexture() {
        // Always read the command params, since they're expected to be consumed.
        let textureNumber = commandInterface.readUInt32()
        let textureWidth = commandInterface.readUInt32()
        let textureHeight = commandInterface.readUInt32()

        // Resolve the texture and its buffer.
        guard let texture = textures[textureNumber] else {
            print("(mglRenderer:updateTexture) invalid textureNumber \(textureNumber), valid numbers are \(textures.keys)")
            return;
        }
        guard let buffer = texture.buffer else {
            print("(mglRenderer:updateTexture) texture doesn't have a buffer to update: \(texture)")
            return;
        }

        // Read the actual image data into the texture.
        let expectedByteCount = Int(mglSizeOfFloatRgbaTexture(textureWidth, textureHeight))
        _ = commandInterface.readBuffer(buffer: buffer, expectedByteCount: expectedByteCount)
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

    func drawDots(view: MTKView, renderEncoder: MTLRenderCommandEncoder) {
        // set the pipeline state
        if (textures.keys.contains(renderTarget)) {
            renderEncoder.setRenderPipelineState(pipelineStateDotsToTexture)
        } else {
            renderEncoder.setRenderPipelineState(pipelineStateDots)
        }

        // Set all the vertex data -- 11 per vertex: [xyz rgba wh isRound borderSize].
        let (vertexBufferDots, vertexCount) = commandInterface.readVertices(device: mglRenderer.device, extraVals: 8)
        renderEncoder.setVertexBuffer(vertexBufferDots, offset: 0, index: 0)

        // Draw all the vertices as points.
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertexCount)
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

    func drawArcs(view: MTKView, renderEncoder: MTLRenderCommandEncoder) {
        if (textures.keys.contains(renderTarget)) {
            renderEncoder.setRenderPipelineState(pipelineStateArcsToTexture)
        } else {
            renderEncoder.setRenderPipelineState(pipelineStateArcs)
        }

        // Set all the vertex data -- 11 per vertex: [xyz rgba inner outer start sweep].
        let (vertexBufferDots, vertexCount) = commandInterface.readVertices(device: mglRenderer.device, extraVals: 9)
        renderEncoder.setVertexBuffer(vertexBufferDots, offset: 0, index: 0)

        // Draw all the vertices as points.
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertexCount)
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

    func bltTexture(view: MTKView, renderEncoder: MTLRenderCommandEncoder) {
        // set the pipeline state
        if (textures.keys.contains(renderTarget)) {
            renderEncoder.setRenderPipelineState(pipelineStateTexturesToTexture)
        } else {
            renderEncoder.setRenderPipelineState(pipelineStateTextures)
        }

        // set up texture sampler
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear
        samplerDescriptor.sAddressMode = MTLSamplerAddressMode.repeat
        samplerDescriptor.tAddressMode = MTLSamplerAddressMode.repeat
        samplerDescriptor.rAddressMode = MTLSamplerAddressMode.repeat
        let samplerState = mglRenderer.device.makeSamplerState(descriptor:samplerDescriptor)
        
        // add the sampler to the renderEncoder
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)

        // read the vertices with 2 extra vals for the texture coordinates
        let (vertexBufferTexture, vertexCount) = commandInterface.readVertices(device: mglRenderer.device, extraVals: 2)

        // set the vertices in the renderEncoder
        renderEncoder.setVertexBuffer(vertexBufferTexture, offset: 0, index: 0)

        // set phase
        var phase = commandInterface.readFloat()
        renderEncoder.setFragmentBytes(&phase, length: MemoryLayout<Float>.stride, index: 2)

        // send the texture to the renderEncoder
        let textureNumber = commandInterface.readUInt32()
        guard let texture = textures[textureNumber] else {
            print("(mglRenderer:bltTexture) invalid textureNumber \(textureNumber), valid numbers are \(textures.keys)")
            return
        }
        renderEncoder.setFragmentTexture(texture, index:0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
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

    func drawVerticesWithColor(view: MTKView, renderEncoder: MTLRenderCommandEncoder, primitiveType: MTLPrimitiveType) {
        // set the pipeline state
        if (textures.keys.contains(renderTarget)) {
            renderEncoder.setRenderPipelineState(pipelineStateVertexWithColorToTexture)
        } else {
            renderEncoder.setRenderPipelineState(pipelineStateVertexWithColor)
        }

        // read the vertices with 3 extra values for color
        let (vertexBufferWithColors, vertexCount) = commandInterface.readVertices(device: mglRenderer.device, extraVals: 3)
        // set the vertices in the renderEncoder
        renderEncoder.setVertexBuffer(vertexBufferWithColors, offset: 0, index: 0)
        // and draw them as triangles
        renderEncoder.drawPrimitives(type: primitiveType, vertexStart: 0, vertexCount: vertexCount)

    }

    func setXform(renderEncoder: MTLRenderCommandEncoder) {
        deg2metal = commandInterface.readXform();
        renderEncoder.setVertexBytes(&deg2metal, length: MemoryLayout<float4x4>.stride, index: 1)
    }
}
