//
//  mglRepeatBltsCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/4/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation
import MetalKit

class mglRepeatBltsCommand : mglCommand {
    private let repeatCount: UInt32

    private var secs = mglSecs()
    private var drawTime: Double = 0.0

    init(repeatCount: UInt32) {
        self.repeatCount = repeatCount
        super.init(framesRemaining: Int(repeatCount))
    }

    init?(commandInterface: mglCommandInterface) {
        guard let repeatCount = commandInterface.readUInt32() else {
            return nil
        }
        self.repeatCount = repeatCount
        super.init(framesRemaining: Int(repeatCount))
    }

    override func draw(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        deg2metal: inout simd_float4x4,
        renderEncoder: MTLRenderCommandEncoder
    ) -> Bool {

        // For now, choose arbitrary vertices to blt onto.
        let vertexByteCount = Int(mglSizeOfFloatVertexArray(6, 5))
        guard let vertexBuffer = view.device?.makeBuffer(length: vertexByteCount, options: .storageModeManaged) else {
            logger.error(component: "mglRepeatBltsCommand", details: "Could not make vertex buffer of size \(vertexByteCount)")
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
        let textureNumbers = colorRenderingState.getTextureNumbers()
        let textureIndex = Int(framesRemaining) % textureNumbers.count
        let textureNumber = textureNumbers[textureIndex]
        guard let texture = colorRenderingState.getTexture(textureNumber: textureNumber) else {
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

        // Record draw time to send back to the client.
        drawTime = secs.get()

        return true
    }

    override func writeQueryResults(
        logger: mglLogger,
        commandInterface : mglCommandInterface
    ) -> Bool {
        // Report to the client when drawing commands were finished.
        _ = commandInterface.writeDouble(data: drawTime)
        return true
    }
}
