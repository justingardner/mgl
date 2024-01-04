//
//  mglColorRenderingConfig.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 5/2/22.
//  Copyright © 2022 GRU. All rights reserved.
//

import Foundation
import MetalKit

/*
 mglColorRenderingState keeps track the current color rendering state for the app, including:
 - whether we're rendering to screen or to an offscreen texture
 - how to set up a rendering pass for screen or texture
 - depth and stencil textures that correspond to the color rendering target

 Color rendering config needs to be applied at a couple of points for each render pass.
 At each point we need to be consistent about what state we're in and which texture to target.
 mglColorRenderingState encloses the state-dependent consistency with a polymorphic/strategy approach,
 which seems nicer than having lots of conditionals in the render pass setup code.
 mglRenderer just needs to call mglColorRenderingState methods at the right times.
 */
class mglColorRenderingState {
    private let logger: mglLogger

    // The usual config for on-screen rendering.
    private var onscreenRenderingConfig: mglColorRenderingConfig!

    // The current config might be onscreenRenderingConfig, or one targeting a specific texture.
    private var currentColorRenderingConfig: mglColorRenderingConfig!

    // A collection of user-managed textures to render to and/or blt to screen.
    private var textureSequence = UInt32(1)
    private var textures : [UInt32: MTLTexture] = [:]

    private let library: MTLLibrary

    init(logger: mglLogger, device: MTLDevice, library: MTLLibrary, view: MTKView) {
        self.logger = logger
        self.library = library

        // Default to onscreen rendering config.
        guard let onscreenRenderingConfig = mglOnscreenRenderingConfig(
            logger: logger,
            device: device,
            library: library,
            view: view
        ) else {
            fatalError("Could not create onscreen rendering config, got nil!")
        }
        self.onscreenRenderingConfig = onscreenRenderingConfig
        self.currentColorRenderingConfig = onscreenRenderingConfig
    }

    // Collaborate with mglRenderer to set up a render pass.
    func getRenderPassDescriptor(view: MTKView) -> MTLRenderPassDescriptor? {
        return currentColorRenderingConfig.getRenderPassDescriptor(view: view)
    }

    // Collaborate with mglRenderer to set up a render pass.
    func finishDrawing(commandBuffer: MTLCommandBuffer, drawable: CAMetalDrawable) {
        return currentColorRenderingConfig.finishDrawing(commandBuffer: commandBuffer, drawable: drawable)
    }

    // Collaborate with mglRenderer to set up a render pass.
    func getDotsPipelineState() -> MTLRenderPipelineState {
        return currentColorRenderingConfig.dotsPipelineState
    }

    // Collaborate with mglRenderer to set up a render pass.
    func getArcsPipelineState() -> MTLRenderPipelineState {
        return currentColorRenderingConfig.arcsPipelineState
    }

    // Collaborate with mglRenderer to set up a render pass.
    func getTexturePipelineState() -> MTLRenderPipelineState {
        return currentColorRenderingConfig.texturePipelineState
    }

    // Collaborate with mglRenderer to set up a render pass.
    func getVerticesWithColorPipelineState() -> MTLRenderPipelineState {
        return currentColorRenderingConfig.verticesWithColorPipelineState
    }

    // Let mglRenderer grab the current fame from a texture target.
    func frameGrab() -> (width: Int, height: Int, pointer: UnsafeMutablePointer<Float>?) {
        return currentColorRenderingConfig.frameGrab()
    }

    // Select a pixel format for onscreen rendering.
    func setOnscreenColorPixelFormat(view: MTKView, pixelFormat: MTLPixelFormat) -> Bool {
        view.colorPixelFormat = pixelFormat

        // Recreate the onscreen color rendering config so that render pipelines will use the new color pixel format.
        guard let newOnscreenRenderingConfig = mglOnscreenRenderingConfig(
            logger: logger,
            device: mglRenderer.device,
            library: library,
            view: view
        ) else {
            logger.error(component: "mglColorRenderingState", details: "Could not create onscreen rendering config for pixel format \(String(describing: view.colorPixelFormat)).")
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

    // Default back to onscreen rendering.
    func setOnscreenRenderingTarget() -> Bool {
        currentColorRenderingConfig = onscreenRenderingConfig
        return true
    }

    // Use the given texture as an offscreen rendering target.
    func setRenderTarget(view: MTKView, targetTexture: MTLTexture) -> Bool {
        guard let newTextureRenderingConfig = mglOffScreenTextureRenderingConfig(
            logger: logger,
            device: mglRenderer.device,
            library: library,
            view: view,
            texture: targetTexture
        ) else {
            logger.error(component: "mglColorRenderingState", details: "Could not create offscreen rendering config, got nil.")
            return false
        }
        currentColorRenderingConfig = newTextureRenderingConfig
        return true
    }

    // Report the size of the onscreen drawable or offscreen texture.
    func getSize(view: MTKView) -> (Float, Float) {
        return currentColorRenderingConfig.getSize(view: view)
    }

    // Add a new texture to the available blt sources and render targets.
    func addTexture(texture: MTLTexture) -> UInt32 {
        // Consume a texture number from the bookkeeping sequence.
        let consumedTextureNumber = textureSequence
        textures[consumedTextureNumber] = texture
        textureSequence += 1
        return consumedTextureNumber
    }

    // Get an existing texture from the collection, if one exists with the given number.
    func getTexture(textureNumber: UInt32) -> MTLTexture? {
        guard let texture = textures[textureNumber] else {
            logger.error(component: "mglColorRenderingState", details: "Can't get invalid texture number \(textureNumber), valid numbers are \(String(describing: textures.keys))")
            return nil
        }
        return texture
    }

    // Remove and return an existing texture from the collection, if one exists with the given number.
    func removeTexture(textureNumber: UInt32) -> MTLTexture? {
        guard let texture = textures.removeValue(forKey: textureNumber) else {
            logger.error(component: "mglColorRenderingState", details: "Can't remove invalid texture number \(textureNumber), valid numbers are \(String(describing: textures.keys))")
            return nil
        }

        logger.info(component: "mglColorRenderingState", details: "Removed texture number \(textureNumber), remaining numbers are \(String(describing: textures.keys))")
        return texture
    }

    func getTextureCount() -> UInt32 {
        return UInt32(textures.count)
    }

    func getTextureNumbers() -> Array<UInt32> {
        return Array(textures.keys).sorted()
    }
}

// This declares the operations that mglRenderer relies on to set up Metal rendering passes and pipelines.
// It will have different implementations for on-screen vs off-screen rendering.
private protocol mglColorRenderingConfig {
    var dotsPipelineState: MTLRenderPipelineState { get }
    var arcsPipelineState: MTLRenderPipelineState { get }
    var verticesWithColorPipelineState: MTLRenderPipelineState { get }
    var texturePipelineState: MTLRenderPipelineState { get }

    func getRenderPassDescriptor(view: MTKView) -> MTLRenderPassDescriptor?
    func getSize(view: MTKView) -> (Float, Float)

    func finishDrawing(commandBuffer: MTLCommandBuffer, drawable: CAMetalDrawable)
    func frameGrab()->(width: Int, height: Int, pointer: UnsafeMutablePointer<Float>?)
}

private class mglOnscreenRenderingConfig : mglColorRenderingConfig {
    private let logger: mglLogger
    let dotsPipelineState: MTLRenderPipelineState
    let arcsPipelineState: MTLRenderPipelineState
    let verticesWithColorPipelineState: MTLRenderPipelineState
    let texturePipelineState: MTLRenderPipelineState

    init?(logger: mglLogger, device: MTLDevice, library: MTLLibrary, view: MTKView) {
        self.logger = logger
        do {
            dotsPipelineState = try device.makeRenderPipelineState(
                descriptor: dotsPipelineStateDescriptor(
                    colorPixelFormat: view.colorPixelFormat,
                    depthPixelFormat: view.depthStencilPixelFormat,
                    stencilPixelFormat: view.depthStencilPixelFormat,
                    library: library))
            arcsPipelineState = try device.makeRenderPipelineState(
                descriptor: arcsPipelineStateDescriptor(
                    colorPixelFormat: view.colorPixelFormat,
                    depthPixelFormat: view.depthStencilPixelFormat,
                    stencilPixelFormat: view.depthStencilPixelFormat,
                    library: library))
            verticesWithColorPipelineState = try device.makeRenderPipelineState(
                descriptor: drawVerticesPipelineStateDescriptor(
                    colorPixelFormat: view.colorPixelFormat,
                    depthPixelFormat: view.depthStencilPixelFormat,
                    stencilPixelFormat: view.depthStencilPixelFormat,
                    library: library))
            texturePipelineState = try device.makeRenderPipelineState(
                descriptor: bltTexturePipelineStateDescriptor(
                    colorPixelFormat: view.colorPixelFormat,
                    depthPixelFormat: view.depthStencilPixelFormat,
                    stencilPixelFormat: view.depthStencilPixelFormat,
                    library: library))
        } catch let error {
            logger.error(component: "mglOnscreenRenderingConfig", details: "Could not create onscreen pipeline state: \(String(describing: error))")
            return nil
        }
    }

    func getRenderPassDescriptor(view: MTKView) -> MTLRenderPassDescriptor? {
        return view.currentRenderPassDescriptor
    }

    func getSize(view: MTKView) -> (Float, Float) {
        return (Float(view.drawableSize.width), Float(view.drawableSize.height))
    }

    func finishDrawing(commandBuffer: MTLCommandBuffer, drawable: CAMetalDrawable) {
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    // frameGrab, since everything is being drawn to a CAMetalDrawable, it does not
    // appear to be trivial to grab the bytes - it seems like a copy of all commands
    // has to be drawn into an offscreen texture, so for now, this function just returns
    // nil to notify that the frameGrab is impossible
    func frameGrab() -> (width: Int, height: Int, pointer: UnsafeMutablePointer<Float>?) {
        logger.error(component: "mglOnscreenRenderingConfig", details: "Cannot get frame because render target is the screen")
        return (0,0,nil)
    }

}

private class mglOffScreenTextureRenderingConfig : mglColorRenderingConfig {
    private let logger: mglLogger
    let dotsPipelineState: MTLRenderPipelineState
    let arcsPipelineState: MTLRenderPipelineState
    let verticesWithColorPipelineState: MTLRenderPipelineState
    let texturePipelineState: MTLRenderPipelineState

    let colorTexture: MTLTexture
    let depthStencilTexture: MTLTexture
    let renderPassDescriptor: MTLRenderPassDescriptor

    init?(logger: mglLogger, device: MTLDevice, library: MTLLibrary, view: MTKView, texture: MTLTexture) {
        self.logger = logger
        self.colorTexture = texture

        let depthStencilTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: view.depthStencilPixelFormat,
            width: texture.width,
            height: texture.height,
            mipmapped: false)
        depthStencilTextureDescriptor.storageMode = .private
        depthStencilTextureDescriptor.usage = .renderTarget
        guard let depthStencilTexture = device.makeTexture(descriptor: depthStencilTextureDescriptor) else {
            logger.error(component: "mglOffScreenTextureRenderingConfig", details: "Could not create offscreen depth-and-stencil texture, got nil!")
            return nil
        }
        self.depthStencilTexture = depthStencilTexture

        renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.depthAttachment.loadAction = .clear
        renderPassDescriptor.depthAttachment.storeAction = .dontCare
        renderPassDescriptor.depthAttachment.texture = depthStencilTexture
        renderPassDescriptor.stencilAttachment.texture = depthStencilTexture

        do {
            dotsPipelineState = try device.makeRenderPipelineState(
                descriptor: dotsPipelineStateDescriptor(
                    colorPixelFormat: texture.pixelFormat,
                    depthPixelFormat: view.depthStencilPixelFormat,
                    stencilPixelFormat: view.depthStencilPixelFormat,
                    library: library))
            arcsPipelineState = try device.makeRenderPipelineState(
                descriptor: arcsPipelineStateDescriptor(
                    colorPixelFormat: texture.pixelFormat,
                    depthPixelFormat: view.depthStencilPixelFormat,
                    stencilPixelFormat: view.depthStencilPixelFormat,
                    library: library))
            verticesWithColorPipelineState = try device.makeRenderPipelineState(
                descriptor: drawVerticesPipelineStateDescriptor(
                    colorPixelFormat: texture.pixelFormat,
                    depthPixelFormat: view.depthStencilPixelFormat,
                    stencilPixelFormat: view.depthStencilPixelFormat,
                    library: library))
            texturePipelineState = try device.makeRenderPipelineState(
                descriptor: bltTexturePipelineStateDescriptor(
                    colorPixelFormat: texture.pixelFormat,
                    depthPixelFormat: view.depthStencilPixelFormat,
                    stencilPixelFormat: view.depthStencilPixelFormat,
                    library: library))
        } catch let error {
            logger.error(component: "mglOffScreenTextureRenderingConfig", details: "Could not create offscreen pipeline state: \(String(describing: error))")
            return nil
        }
    }

    func getRenderPassDescriptor(view: MTKView) -> MTLRenderPassDescriptor? {
        renderPassDescriptor.colorAttachments[0].clearColor = view.clearColor
        renderPassDescriptor.depthAttachment.clearDepth = view.clearDepth
        return renderPassDescriptor
    }

    func getSize(view: MTKView) -> (Float, Float) {
        return (Float(colorTexture.width), Float(colorTexture.height))
    }

    func finishDrawing(commandBuffer: MTLCommandBuffer, drawable: CAMetalDrawable) {
        let bltCommandEncoder = commandBuffer.makeBlitCommandEncoder()
        bltCommandEncoder?.synchronize(resource: colorTexture)
        bltCommandEncoder?.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()

        // Wait until the bltCommandEncoder is done syncing data from GPU to CPU.
        commandBuffer.waitUntilCompleted()
    }

    // frameGrab, this will write the bytes of the texture into an array
    func frameGrab() -> (width: Int, height: Int, pointer: UnsafeMutablePointer<Float>?) {
        // first make sure we have the right MTLTexture format (this should always be the same - it's set in
        // the createTexture function in mglCommandInterface
        if (colorTexture.pixelFormat == MTLPixelFormat.rgba32Float) {
            // compute size needed
            let dataSize = colorTexture.width * colorTexture.height * 4 * MemoryLayout<Float>.stride
            // set the region
            let region = MTLRegionMake2D(0,0,colorTexture.width,colorTexture.height)
            let bytesPerRow = colorTexture.width * 4 * MemoryLayout<Float>.stride
            let destinationBuffer = UnsafeMutablePointer<Float>.allocate(capacity: dataSize)
            // just for debugging, set to a value, to make sure we can retrieve that, if nothing else.
            destinationBuffer.initialize(repeating: 45, count: dataSize)
            // ok, get the bytes
            colorTexture.getBytes(destinationBuffer, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
            // return pointer to frame data
            return (colorTexture.width, colorTexture.height, destinationBuffer)
        }
        else {
            // write log message
            logger.error(component: "mglOffScreenTextureRenderingConfig", details: "Cannot get frame because render target texture is not in rgba32float format")

            // could not get bytes, return 0,0,nil
            return (0,0,nil)
        }
    }
}

private func dotsPipelineStateDescriptor(colorPixelFormat:  MTLPixelFormat, depthPixelFormat:  MTLPixelFormat, stencilPixelFormat:  MTLPixelFormat, library: MTLLibrary?) -> MTLRenderPipelineDescriptor {
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

private func arcsPipelineStateDescriptor(colorPixelFormat:  MTLPixelFormat, depthPixelFormat:  MTLPixelFormat, stencilPixelFormat:  MTLPixelFormat, library: MTLLibrary?) -> MTLRenderPipelineDescriptor {
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
    // xyz
    vertexDescriptor.attributes[0].format = .float3
    vertexDescriptor.attributes[0].offset = 0
    vertexDescriptor.attributes[0].bufferIndex = 0
    // rgba
    vertexDescriptor.attributes[1].format = .float4
    vertexDescriptor.attributes[1].offset = 3 * MemoryLayout<Float>.stride
    vertexDescriptor.attributes[1].bufferIndex = 0
    // radii
    vertexDescriptor.attributes[2].format = .float4
    vertexDescriptor.attributes[2].offset = 7 * MemoryLayout<Float>.stride
    vertexDescriptor.attributes[2].bufferIndex = 0
    // wedge
    vertexDescriptor.attributes[3].format = .float2
    vertexDescriptor.attributes[3].offset = 11 * MemoryLayout<Float>.stride
    vertexDescriptor.attributes[3].bufferIndex = 0
    // border
    vertexDescriptor.attributes[4].format = .float
    vertexDescriptor.attributes[4].offset = 13 * MemoryLayout<Float>.stride
    vertexDescriptor.attributes[4].bufferIndex = 0
    // center vertex (computed)
    vertexDescriptor.attributes[5].format = .float3
    vertexDescriptor.attributes[5].offset = 14 * MemoryLayout<Float>.stride
    vertexDescriptor.attributes[5].bufferIndex = 0
    // viewport size
    vertexDescriptor.attributes[6].format = .float2
    vertexDescriptor.attributes[6].offset = 17 * MemoryLayout<Float>.stride
    vertexDescriptor.attributes[6].bufferIndex = 0
    vertexDescriptor.layouts[0].stride = 19 * MemoryLayout<Float>.stride
    pipelineDescriptor.vertexDescriptor = vertexDescriptor
    pipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertex_arcs")
    pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragment_arcs")

    return pipelineDescriptor
}

private func bltTexturePipelineStateDescriptor(colorPixelFormat:  MTLPixelFormat, depthPixelFormat:  MTLPixelFormat, stencilPixelFormat:  MTLPixelFormat, library: MTLLibrary?) -> MTLRenderPipelineDescriptor {
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

private func drawVerticesPipelineStateDescriptor(colorPixelFormat:  MTLPixelFormat, depthPixelFormat:  MTLPixelFormat, stencilPixelFormat:  MTLPixelFormat, library: MTLLibrary?) -> MTLRenderPipelineDescriptor {
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
