//
//  mglDotsCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/4/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation
import MetalKit

class mglDotsCommand : mglCommand {
    private let vertexBufferDots: MTLBuffer
    private let vertexCount: Int

    init(vertexBufferDots: MTLBuffer, vertexCount: Int) {
        self.vertexBufferDots = vertexBufferDots
        self.vertexCount = vertexCount
        super.init(framesRemaining: 1)
    }

    init?(commandInterface: mglCommandInterface, device: MTLDevice) {
        guard let (vertexBufferDots, vertexCount) = commandInterface.readVertices(device: device, extraVals: 8) else {
            return nil
        }
        self.vertexBufferDots = vertexBufferDots
        self.vertexCount = vertexCount
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
        // Draw all the vertices as points with 11 values per vertex: [xyz rgba wh isRound borderSize].
        renderEncoder.setRenderPipelineState(colorRenderingState.getDotsPipelineState())
        renderEncoder.setVertexBuffer(vertexBufferDots, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertexCount)
        return true
    }

}
