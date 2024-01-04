//
//  mglBltTextureCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/4/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation
import MetalKit

class mglBltTextureCommand : mglCommand {
    private let minMagFilter: MTLSamplerMinMagFilter
    private let mipFilter: MTLSamplerMipFilter
    private let addressMode: MTLSamplerAddressMode
    private let vertexBufferTexture: MTLBuffer
    private let vertexCount: Int
    private var phase: Float32
    private let textureNumber: UInt32

    init(
        minMagFilter: MTLSamplerMinMagFilter = .linear,
        mipFilter: MTLSamplerMipFilter = .linear,
        addressMode: MTLSamplerAddressMode = .repeat,
        vertexBufferTexture: MTLBuffer,
        vertexCount: Int,
        phase: Float32 = 0.0,
        textureNumber: UInt32
    ) {
        self.minMagFilter = minMagFilter
        self.mipFilter = mipFilter
        self.addressMode = addressMode
        self.vertexBufferTexture = vertexBufferTexture
        self.vertexCount = vertexCount
        self.phase = phase
        self.textureNumber = textureNumber
        super.init(framesRemaining: 1)
    }

    init?(commandInterface: mglCommandInterface, device: MTLDevice) {
        guard let minMagFilterRawValue = commandInterface.readUInt32(),
              let mipFilterRawValue = commandInterface.readUInt32(),
              let addressModeRawValue = commandInterface.readUInt32(),
              let (vertexBufferTexture, vertexCount) = commandInterface.readVertices(device: device, extraVals: 2),
              let phase = commandInterface.readFloat(),
              let textureNumber = commandInterface.readUInt32() else {
            return nil
        }
        self.minMagFilter = chooseMinMagFilter(rawValue: minMagFilterRawValue)
        self.mipFilter = chooseMipFilter(rawValue: mipFilterRawValue)
        self.addressMode = chooseAddressMode(rawValue: addressModeRawValue)
        self.vertexBufferTexture = vertexBufferTexture
        self.vertexCount = vertexCount
        self.phase = phase
        self.textureNumber = textureNumber
        super.init(framesRemaining: 1)
    }

    override func draw(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        deg2metal: inout simd_float4x4,
        renderEncoder: MTLRenderCommandEncoder
    ) -> Bool {
        // Make sure we have the actual requested texture.
        guard let texture = colorRenderingState.getTexture(textureNumber: textureNumber) else {
            return false
        }

        // Set up texture sampling and filtering.
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = minMagFilter
        samplerDescriptor.magFilter = minMagFilter
        samplerDescriptor.mipFilter = mipFilter
        samplerDescriptor.sAddressMode = addressMode
        samplerDescriptor.tAddressMode = addressMode
        samplerDescriptor.rAddressMode = addressMode
        let samplerState = mglRenderer.device.makeSamplerState(descriptor: samplerDescriptor)

        // Draw vertices as points with 5 values per vertex: [xyz uv].
        renderEncoder.setRenderPipelineState(colorRenderingState.getTexturePipelineState())
        renderEncoder.setVertexBuffer(vertexBufferTexture, offset: 0, index: 0)
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)
        renderEncoder.setFragmentBytes(&phase, length: MemoryLayout<Float>.stride, index: 2)
        renderEncoder.setFragmentTexture(texture, index:0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)

        return true
    }

}

private func chooseMinMagFilter(rawValue: UInt32, defaultValue: MTLSamplerMinMagFilter = .linear) -> MTLSamplerMinMagFilter {
    guard let filter = MTLSamplerMinMagFilter(rawValue: UInt(rawValue)) else {
        return defaultValue
    }
    return filter
}

private func chooseMipFilter(rawValue: UInt32, defaultValue: MTLSamplerMipFilter = .linear) -> MTLSamplerMipFilter {
    guard let filter = MTLSamplerMipFilter(rawValue: UInt(rawValue)) else {
        return defaultValue
    }
    return filter
}

private func chooseAddressMode(rawValue: UInt32, defaultValue: MTLSamplerAddressMode = .repeat) -> MTLSamplerAddressMode {
    guard let filter = MTLSamplerAddressMode(rawValue: UInt(rawValue)) else {
        return defaultValue
    }
    return filter
}
