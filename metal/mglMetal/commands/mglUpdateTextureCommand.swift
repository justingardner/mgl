//
//  mglUpdateTextureCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/4/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation
import MetalKit

class mglUpdateTextureCommand : mglCommand {
    private let textureNumber: UInt32
    private let newTexture: MTLTexture

    init(textureNumber: UInt32, newTexture: MTLTexture) {
        self.textureNumber = textureNumber
        self.newTexture = newTexture
        super.init(framesRemaining: 1)
    }

    // This reads the new, incoming texture data into a temporary texture buffer.
    // Then later, this copies the new data into the existing texture's buffer.
    // We used to copy bytes directly from the command interface to the existing texture's bufffer, and this was nice.
    // In order to support queued batches of commands, which are all read in ahead of time before processing / rendering,
    // We need to allow some separation in time.
    // Otherwise, all queued updates for the same texture would get clobbered by the last update.
    init?(commandInterface: mglCommandInterface, device: MTLDevice) {
        guard let textureNumber = commandInterface.readUInt32(),
              let newTexture = commandInterface.createTexture(device: device) else {
            return nil
        }
        self.textureNumber = textureNumber
        self.newTexture = newTexture
        super.init(framesRemaining: 1)
    }

    override func doNondrawingWork(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        renderer: mglRenderer2,
        deg2metal: inout simd_float4x4,
        targetPresentationTimestamp: CFTimeInterval?
    ) -> Bool {
        // Resolve the existing texture and sanity check against the new, incoming texture.
        guard let existingTexture = colorRenderingState.getTexture(textureNumber: textureNumber) else {
            return false
        }

        if (newTexture.width != existingTexture.width || newTexture.height != existingTexture.height) {
            logger.error(component: "mglUpdateTextureCommand", details: "Textures are not the same size: new \(newTexture.width) x \(newTexture.height) vs existing \(existingTexture.width) x \(existingTexture.height)")
            return false
        }

        guard let existingBuffer = existingTexture.buffer else {
            logger.error(component: "mglUpdateTextureCommand", details: "Existing texture has no buffer to update: \(String(describing: existingTexture))")
            return false
        }

        guard let newBuffer = newTexture.buffer else {
            logger.error(component: "mglUpdateTextureCommand", details: "New texture has no buffer to update: \(String(describing: newTexture))")
            return false
        }

        if (newBuffer.allocatedSize != existingBuffer.allocatedSize) {
            logger.error(component: "mglUpdateTextureCommand", details: "Texture buffers are not the same size: new \(newBuffer.allocatedSize) vs existing \(existingBuffer.allocatedSize)")
            return false
        }

        // Copy actual image data from the new, incoming texture to the existing texture, in place.
        existingBuffer.contents().copyMemory(from: newBuffer.contents(), byteCount: existingBuffer.allocatedSize)
        existingBuffer.didModifyRange(0 ..< existingBuffer.allocatedSize)
        return true
    }
}
