//
//  mglColorRenderingConfig.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 5/2/22.
//  Copyright © 2022 GRU. All rights reserved.
//

import Foundation
import MetalKit
import os.log

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
    // The usual config for on-screen rendering.
    private var onscreenRenderingConfig: mglColorRenderingConfig!

    // The current config might be onscreenRenderingConfig, or one targeting a specific texture.
    private var currentColorRenderingConfig: mglColorRenderingConfig!

    init(device: MTLDevice, library: MTLLibrary, view: MTKView) {
        // Default to onscreen rendering config.
        guard let onscreenRenderingConfig = mglOnscreenRenderingConfig(device: device, library: library, view: view) else {
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
    func setOnscreenColorPixelFormat(view: MTKView, library: MTLLibrary, pixelFormat: MTLPixelFormat) -> Bool {
        view.colorPixelFormat = pixelFormat

        // Recreate the onscreen color rendering config so that render pipelines will use the new color pixel format.
        guard let newOnscreenRenderingConfig = mglOnscreenRenderingConfig(device: mglRenderer.device, library: library, view: view) else {
            os_log("(mglColorRenderingState) Could not create onscreen rendering config for pixel format %{public}@.",
                   log: .default, type: .error, String(describing: view.colorPixelFormat))
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
    func setRenderTarget(view: MTKView, library: MTLLibrary, targetTexture: MTLTexture) -> Bool {
        guard let newTextureRenderingConfig = mglOffScreenTextureRenderingConfig(device: mglRenderer.device, library: library, view: view, texture: targetTexture) else {
            os_log("(mglColorRenderingState) Could not create offscreen rendering config, got nil.",
                   log: .default, type: .error)
            return false
        }
        currentColorRenderingConfig = newTextureRenderingConfig
        return true
    }

    // Report the size of the onscreen drawable or offscreen texture.
    func getSize(view: MTKView) -> (Float, Float){
        return currentColorRenderingConfig.getSize(view: view)
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
    let dotsPipelineState: MTLRenderPipelineState
    let arcsPipelineState: MTLRenderPipelineState
    let verticesWithColorPipelineState: MTLRenderPipelineState
    let texturePipelineState: MTLRenderPipelineState

    init?(device: MTLDevice, library: MTLLibrary, view: MTKView) {
        // Until an explicit OOP command model exists, we can just call static functions of mglRenderer.
        do {
            dotsPipelineState = try device.makeRenderPipelineState(
                descriptor: mglRenderer.dotsPipelineStateDescriptor(
                    colorPixelFormat: view.colorPixelFormat,
                    depthPixelFormat: view.depthStencilPixelFormat,
                    stencilPixelFormat: view.depthStencilPixelFormat,
                    library: library))
            arcsPipelineState = try device.makeRenderPipelineState(
                descriptor: mglRenderer.arcsPipelineStateDescriptor(
                    colorPixelFormat: view.colorPixelFormat,
                    depthPixelFormat: view.depthStencilPixelFormat,
                    stencilPixelFormat: view.depthStencilPixelFormat,
                    library: library))
            verticesWithColorPipelineState = try device.makeRenderPipelineState(
                descriptor: mglRenderer.drawVerticesPipelineStateDescriptor(
                    colorPixelFormat: view.colorPixelFormat,
                    depthPixelFormat: view.depthStencilPixelFormat,
                    stencilPixelFormat: view.depthStencilPixelFormat,
                    library: library))
            texturePipelineState = try device.makeRenderPipelineState(
                descriptor: mglRenderer.bltTexturePipelineStateDescriptor(
                    colorPixelFormat: view.colorPixelFormat,
                    depthPixelFormat: view.depthStencilPixelFormat,
                    stencilPixelFormat: view.depthStencilPixelFormat,
                    library: library))
        } catch let error {
            os_log("Could not create onscreen pipeline state: %@", log: .default, type: .error, String(describing: error))
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
        os_log("(mglColorRenderingConfig:frameGrab) Cannot get frame because render target is the screen", log: .default, type: .error)
        return (0,0,nil)
    }

}

private class mglOffScreenTextureRenderingConfig : mglColorRenderingConfig {
    let dotsPipelineState: MTLRenderPipelineState
    let arcsPipelineState: MTLRenderPipelineState
    let verticesWithColorPipelineState: MTLRenderPipelineState
    let texturePipelineState: MTLRenderPipelineState

    let colorTexture: MTLTexture
    let depthStencilTexture: MTLTexture
    let renderPassDescriptor: MTLRenderPassDescriptor

    init?(device: MTLDevice, library: MTLLibrary, view: MTKView, texture: MTLTexture) {
        self.colorTexture = texture

        let depthStencilTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: view.depthStencilPixelFormat,
            width: texture.width,
            height: texture.height,
            mipmapped: false)
        depthStencilTextureDescriptor.storageMode = .private
        depthStencilTextureDescriptor.usage = .renderTarget
        guard let depthStencilTexture = device.makeTexture(descriptor: depthStencilTextureDescriptor) else {
            os_log("Could not create offscreen depth-and-stencil texture, got nil!", log: .default, type: .error)
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
                descriptor: mglRenderer.dotsPipelineStateDescriptor(
                    colorPixelFormat: texture.pixelFormat,
                    depthPixelFormat: view.depthStencilPixelFormat,
                    stencilPixelFormat: view.depthStencilPixelFormat,
                    library: library))
            arcsPipelineState = try device.makeRenderPipelineState(
                descriptor: mglRenderer.arcsPipelineStateDescriptor(
                    colorPixelFormat: texture.pixelFormat,
                    depthPixelFormat: view.depthStencilPixelFormat,
                    stencilPixelFormat: view.depthStencilPixelFormat,
                    library: library))
            verticesWithColorPipelineState = try device.makeRenderPipelineState(
                descriptor: mglRenderer.drawVerticesPipelineStateDescriptor(
                    colorPixelFormat: texture.pixelFormat,
                    depthPixelFormat: view.depthStencilPixelFormat,
                    stencilPixelFormat: view.depthStencilPixelFormat,
                    library: library))
            texturePipelineState = try device.makeRenderPipelineState(
                descriptor: mglRenderer.bltTexturePipelineStateDescriptor(
                    colorPixelFormat: texture.pixelFormat,
                    depthPixelFormat: view.depthStencilPixelFormat,
                    stencilPixelFormat: view.depthStencilPixelFormat,
                    library: library))
        } catch let error {
            os_log("(mglColorRenderingConfig) Could not create offscreen pipeline state: %@", log: .default, type: .error, String(describing: error))
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
            os_log("(mglColorRenderingConfig:frameGrab) Render target texture is not in rgba32float format", log: .default, type: .error)

            // could not get bytes, return 0,0,nil
            return (0,0,nil)
        }
    }
}
