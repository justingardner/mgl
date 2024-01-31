//
//  mglCreateVideoCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/31/24.
//  Copyright © 2024 GRU. All rights reserved.
//

// This is a sketch based on this Objective-C example:
// https://developer.apple.com/videos/play/wwdc2020/10090/

import Foundation
import MetalKit
import AVFoundation

struct mglVideo {
    let asset: AVAsset
    let assetReader: AVAssetReader
    let track: AVAssetTrack
    let trackOutput: AVAssetReaderTrackOutput
    var textureCache: CVMetalTextureCache!

    init?(filePath: String, device: MTLDevice, logger: mglLogger) {
        let url = NSURL.fileURL(withPath: filePath, isDirectory: false)
        asset = AVAsset(url: url)
        do {
            try assetReader = AVAssetReader(asset: asset)
        } catch {
            logger.error(component: "mglVideo", details: "Can't read asset at path: \(filePath)")
            return nil
        }

        guard let firstVideoTrack = asset.tracks(withMediaType: AVMediaType.video).first else {
            logger.error(component: "mglVideo", details: "Can't find first video track of asset at path: \(filePath)")
            return nil
        }
        track = firstVideoTrack

        // From AVAssetReaderTrackOutput docs:
        // In macOS, kCVPixelFormatType_422YpCbCr8 is the preferred pixel format for video
        // and generally provides the best performance when decoding. If you need to work
        // in the RGB domain, use kCVPixelFormatType_32BGRA in iOS, and kCVPixelFormatType_32ARGB in macOS.
        // We're on macOS but I'm choosing kCVPixelFormatType_32BGRA to match MTLPixelFormat.bgra8Unorm in nextTexture(), below.
        let outputSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        trackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
        trackOutput.alwaysCopiesSampleData = false
        assetReader.add(trackOutput)

        // A runtime warning:
        // "This method should not be called on the main thread as it may lead to UI unresponsiveness."
        let reading = assetReader.startReading()
        if !reading {
            logger.error(
                component: "mglVideo",
                details: "Error reading from from: \(filePath) status: \(assetReader.status) error: \(String(describing: assetReader.error))")
            return nil
        }

        let cacheCreateResult = CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache)
        if cacheCreateResult != kCVReturnSuccess {
            logger.error(
                component: "mglVideo",
                details: "Can't create CVMetalTextureCache for: \(filePath) result: \(cacheCreateResult)")
            return nil
        }
    }

    func nextTexture(logger: mglLogger) -> MTLTexture? {
        guard let sampleBuffer = trackOutput.copyNextSampleBuffer() else {
            logger.error(
                component: "mglVideo",
                details: "Can't copy sample buffer status: \(assetReader.status) error: \(String(describing: assetReader.error))")
            return nil
        }

        // TODO: handle sample Buffer errors and also legit marker buffers with no image.
        guard let imageBuffer = sampleBuffer.imageBuffer else {
            logger.error(
                component: "mglVideo",
                details: "Got no image buffer status: \(assetReader.status) error: \(String(describing: assetReader.error))")
            return nil
        }

        // We chose kCVPixelFormatType_32BGRA in init() above, to match MTLPixelFormat.bgra8Unorm here.
        var cvMetalTexture: CVMetalTexture!
        let textureCreateResult = CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache,
            imageBuffer,
            nil,
            MTLPixelFormat.bgra8Unorm,
            CVPixelBufferGetWidth(imageBuffer),
            CVPixelBufferGetHeight(imageBuffer),
            0,
            &cvMetalTexture
        )
        if textureCreateResult != kCVReturnSuccess {
            logger.error(component: "mglVideo", details: "Can't create CVMetalTexture result: \(textureCreateResult)")
            return nil
        }

        guard let texture = CVMetalTextureGetTexture(cvMetalTexture) else {
            logger.error(component: "mglVideo", details: "Can't get Metal texture from Core Video Texture!")
            return nil
        }
        return texture
    }
}


class mglCreateVideoCommand : mglCommand {
    let filePath: String
    var video: mglVideo?

    init(filePath: String) {
        self.filePath = filePath
        super.init(framesRemaining: 1)
    }

    override func doNondrawingWork(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        deg2metal: inout simd_float4x4
    ) -> Bool {
        // TODO: this is a dumb way to reuse the same command in sketchy testing.
        framesRemaining = 1

        // TODO: manage this kind of state with separate commands.
        if (video == nil) {
            video = mglVideo(filePath: filePath, device: view.device!, logger: logger)
            if (video == nil) {
                logger.error(component: "mglCreateVideoCommand", details: "Creating mglVideo failed for: \(filePath)")
                return false
            }
        }
        return video != nil
    }

    override func draw(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        deg2metal: inout simd_float4x4,
        renderEncoder: MTLRenderCommandEncoder
    ) -> Bool {
        // TODO: distinguish video completed from other errors.
        guard let texture = video?.nextTexture(logger: logger) else {
            return false
        }
        // TODO: would want to free cvMetalTexture in a command buffer completion handler.
        // TODO: add commandBuffer to draw() signature?

        // For now, choose arbitrary vertices to blt onto.
        let vertexByteCount = Int(mglSizeOfFloatVertexArray(6, 5))
        guard let vertexBuffer = view.device?.makeBuffer(length: vertexByteCount, options: .storageModeManaged) else {
            logger.error(component: "mglRepeatBltsCommand", details: "Could not make vertex buffer of size \(vertexByteCount)")
            return false
        }
        let w = Float32(1.0)
        let h = Float32(0.5625)
        let vertexData: [Float32] = [
            w,  h, 0, 1, 0,
            -w,  h, 0, 0, 0,
            -w, -h, 0, 0, 1,
            w,  h, 0, 1, 0,
            -w, -h, 0, 0, 1,
            w, -h, 0, 1, 1
        ]
        let bufferFloats = vertexBuffer.contents().bindMemory(to: Float32.self, capacity: vertexData.count)
        bufferFloats.update(from: vertexData, count: vertexData.count)

        // For now, choose an arbitrary, fixed sampling strategy.
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .nearest
        samplerDescriptor.magFilter = .nearest
        samplerDescriptor.mipFilter = .nearest
        samplerDescriptor.sAddressMode = .repeat
        samplerDescriptor.tAddressMode = .repeat
        samplerDescriptor.rAddressMode = .repeat
        guard let samplerState = view.device?.makeSamplerState(descriptor:samplerDescriptor) else {
            logger.error(component: "mglRepeatBltsCommand", details: "Could not make makeSamplerState.")
            return false
        }

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
}
