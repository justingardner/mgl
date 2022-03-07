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

    // Conversion of mesh into metal vertices
    var vertexBuffer: MTLBuffer!

    // Pipeline states for rendering different things
    var pipelineStateDots: MTLRenderPipelineState!
    var pipelineStateVertexWithColor: MTLRenderPipelineState!
    var pipelineStateVertexWithColorForTexture: MTLRenderPipelineState!
    var pipelineStateTextures: MTLRenderPipelineState!

    // variable to hold mglCommunicator which
    // communicates with matlab
    var commandInterface : mglCommandInterface
    
    // sets whether to send a flush confirm back to matlab
    var acknowledgeFlush = false

    // sets whether to wait each flush for commands from matlab
    var blocking = false

    // keeps coordinate xform
    var deg2metal = matrix_identity_float4x4

    var textures : [MTLTexture] = []

    // target for rendering: either an index into textures, or else render off-screen.
    var renderTarget = Array<MTLTexture>.Index(-1)
    
    // Set to not provide profiling information
    var profile = false
    var secs = mglSecs()
    
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

        // Set up several rendering pipelines, all will have a pixel format and alpha blending in common.
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled           = true;
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation           = MTLBlendOperation.add;
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation         = MTLBlendOperation.add;
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor        = MTLBlendFactor.sourceAlpha;
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor      = MTLBlendFactor.sourceAlpha;
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor   = MTLBlendFactor.oneMinusSourceAlpha;
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactor.oneMinusSourceAlpha;
        
        // Set up a pipelineState for rendering dots
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD3<Float>>.size
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertex_dots")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragment_dots")
        // Setup the pipeline with the device
        do {
            pipelineStateDots = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }

        // Set up a pipelineState for rendering textures
        // add attribute for texture coordinates
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = 3 * MemoryLayout<Float>.size
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = 5 * MemoryLayout<Float>.size

        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertex_textures")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragment_textures")
        // Setup the pipeline with the device
        do {
            pipelineStateTextures = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }

        // add attribute for color
        vertexDescriptor.attributes[1].format = .float3
        vertexDescriptor.attributes[1].offset = 3 * MemoryLayout<Float>.size
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = 6 * MemoryLayout<Float>.size

        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertex_with_color")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragment_with_color")
        // Setup the pipeline with the device
        do {
            pipelineStateVertexWithColor = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }

        pipelineDescriptor.colorAttachments[0].pixelFormat = .rgba32Float
        do {
            pipelineStateVertexWithColorForTexture = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }

        // init the super class
        super.init()
        
        // Set the clear color for the view
        metalView.clearColor = MTLClearColor(red: 0.5, green: 0.5,
                                             blue: 0.5, alpha: 1)
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
        print("(mglMetal:mglRenderer) drawableSizeWillChange \(size)")
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
            case mglCreateTexture: createTexture()
            case mglReadTexture: readTexture()
            case mglSetRenderTarget: setRenderTarget()
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

        // Configure a render pass to target on-screen as usuaal, or an offscreen texture if one was chosen.
        guard let descriptor = view.currentRenderPassDescriptor else {
                  // We did nothing, but Matlab still expectes a command-processed ack.
                  _ = commandInterface.writeDouble(data: secs.get())
                  return
              }
        if (textures.indices.contains(renderTarget)) {
            descriptor.colorAttachments[0].texture = textures[renderTarget]
            descriptor.colorAttachments[0].loadAction = .clear
            descriptor.colorAttachments[0].clearColor = view.clearColor
            descriptor.colorAttachments[0].storeAction = .store
        }

        guard let commandBuffer = mglRenderer.commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
                  // We did nothing, but Matlab still expectes a command-processed ack.
                  _ = commandInterface.writeDouble(data: secs.get())
                  return
              }

        renderEncoder.setVertexBytes(&deg2metal, length: MemoryLayout<float4x4>.stride, index: 1)

        // Keep processing drawing commands until a flush command.
        while (command != mglFlush) {
            switch command {
            case mglClearScreen: clearScreen(view : view, renderEncoder: renderEncoder)
            case mglBltTexture: bltTexture(view: view, renderEncoder: renderEncoder)
            case mglSetXform: setXform(renderEncoder: renderEncoder)
            case mglDots: dots(view: view, renderEncoder: renderEncoder)
            case mglLine: drawVerticesWithColor(view: view, renderEncoder: renderEncoder, primitiveType: .line)
            case mglQuad: drawVerticesWithColor(view: view, renderEncoder: renderEncoder, primitiveType: .triangle)
            case mglPolygon: drawVerticesWithColor(view: view, renderEncoder: renderEncoder, primitiveType: .triangleStrip)
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

        if (textures.indices.contains(renderTarget)) {
            let bltCommandEncoder = commandBuffer.makeBlitCommandEncoder()
            bltCommandEncoder?.synchronize(resource: textures[renderTarget])
            bltCommandEncoder?.endEncoding()
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    func drainSystemEvents(view: MTKView) {
        guard let window = view.window else {return}
        var event = window.nextEvent(matching: .any)
        while (event != nil) {
            print("(mglRenderer) Processing OS event: \(String(describing: event))")
            event = window.nextEvent(matching: .any)
        }
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // clearScreen
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func clearScreen(view: MTKView, renderEncoder: MTLRenderCommandEncoder) {
        let color = commandInterface.readColor()
        view.clearColor = MTLClearColor(red: Double(color[0]), green: Double(color[1]), blue: Double(color[2]), alpha: 1)
    }
    
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // dots
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func dots(view: MTKView, renderEncoder: MTLRenderCommandEncoder) {
        // set the pipeline state
        renderEncoder.setRenderPipelineState(pipelineStateDots)

        // Set the point size to use for all vertices.
        var pointSize = commandInterface.readFloat();
        renderEncoder.setVertexBytes(&pointSize, length: MemoryLayout<Float>.size, index: 2);

        // Set the color to use for all dots.
        var color = commandInterface.readColor();
        renderEncoder.setFragmentBytes(&color, length: MemoryLayout<simd_float3>.stride, index: 0)

        // Set the shape to use for all dots.
        var isRound = commandInterface.readUInt32();
        renderEncoder.setFragmentBytes(&isRound, length: MemoryLayout<UInt32>.size, index: 1);

        // read the vertices
        let (vertexBufferDots, vertexCount) = commandInterface.readVertices(device: mglRenderer.device)

        // set the vertices in the renderEncoder
        renderEncoder.setVertexBuffer(vertexBufferDots, offset: 0, index: 0)
        // and draw them as points
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertexCount)
    }
    
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // bltTexture
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func bltTexture(view: MTKView, renderEncoder: MTLRenderCommandEncoder) {
        let textureNumber = commandInterface.readUInt32()
        let textureIndex = Array<MTLTexture>.Index(textureNumber)
        if (!textures.indices.contains(textureIndex)) {
            print("(mglRenderer:bltTexture) given textureNumber \(textureNumber) is invalid, ie not in texture indices \(textures.indices).")
            return;
        }
        let texture = textures[textureIndex]

        // set the pipeline state
        renderEncoder.setRenderPipelineState(pipelineStateTextures)

        // set up texture sampler
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear
        samplerDescriptor.sAddressMode = MTLSamplerAddressMode.clampToEdge
        samplerDescriptor.tAddressMode = MTLSamplerAddressMode.clampToEdge
        samplerDescriptor.rAddressMode = MTLSamplerAddressMode.clampToEdge
        let samplerState = mglRenderer.device.makeSamplerState(descriptor:samplerDescriptor)
        
        // add the sampler to the renderEncoder
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)

        // read the vertices with 2 extra vals for the texture coordinates
        let (vertexBufferTexture, vertexCount) = commandInterface.readVertices(device: mglRenderer.device, extraVals: 2)

        // set the vertices in the renderEncoder
        renderEncoder.setVertexBuffer(vertexBufferTexture, offset: 0, index: 0)

        // send the texture to the renderEncoder
        renderEncoder.setFragmentTexture(texture, index:0)

        // set phase
        var phase = commandInterface.readFloat()
        renderEncoder.setFragmentBytes(&phase, length: MemoryLayout<Float>.stride, index: 2)

        // and draw them as a triangle
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // createTexture
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func createTexture() {
        let texture = commandInterface.readTexture(device: mglRenderer.device)
        textures.append(texture)

        // Return the textureNumber of the new texture.
        let textureCount = mglUInt32(textures.count)
        _ = commandInterface.writeUInt32(data: textureCount - 1)

        // Return the total number of textures.
        _ = commandInterface.writeUInt32(data: textureCount)
    }

    func readTexture() {
        let textureNumber = commandInterface.readUInt32()
        let textureIndex = Array<MTLTexture>.Index(textureNumber)
        if (!textures.indices.contains(textureIndex)) {
            print("(mglRenderer:readTexture) given textureNumber \(textureNumber) is invalid, ie not in texture indices \(textures.indices).")
            // No data to return, but Matlab expects a response wiht width and height.
            _ = commandInterface.writeUInt32(data: 0)
            _ = commandInterface.writeUInt32(data: 0)
            return;
        }
        let texture = textures[textureIndex]
        _ = commandInterface.writeTexture(texture: texture)
    }

    func setRenderTarget() {
        renderTarget = Array<MTLTexture>.Index(commandInterface.readUInt32())
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // drawVerticesWithColor
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func drawVerticesWithColor(view: MTKView, renderEncoder: MTLRenderCommandEncoder, primitiveType: MTLPrimitiveType) {
        // set the pipeline state
        if (textures.indices.contains(renderTarget)) {
            renderEncoder.setRenderPipelineState(pipelineStateVertexWithColorForTexture)
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

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // windowed
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func windowed(view: MTKView) {
        guard let window = view.window else {
            print("(mglRenderer:windowed) Could not retrieve window")
            return
        }

        if !window.styleMask.contains(.fullScreen) {
            print("(mglRenderer:windowed) Is already windowed")
        } else {
            window.toggleFullScreen(nil)
            var windowFrame = window.frame
            print(windowFrame)
            windowFrame.size = NSMakeSize(400, 400)
            window.setFrame(windowFrame, display: true)
            NSCursor.unhide()
        }
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // fullscreen
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
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
}
