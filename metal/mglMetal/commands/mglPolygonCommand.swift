//
//  mglPolygonCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/4/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation
import MetalKit

class mglPolygonCommand : mglCommand {
    private let vertexBufferWithColors: MTLBuffer
    private let vertexCount: Int

    init(vertexBufferWithColors: MTLBuffer, vertexCount: Int) {
        self.vertexBufferWithColors = vertexBufferWithColors
        self.vertexCount = vertexCount
        super.init(framesRemaining: 1)
    }

    init?(commandInterface: mglCommandInterface, device: MTLDevice) {
        // Read and buffer vertices as points with 6 values per vertex: [xyz rgb]
        guard let (vertexBufferWithColors, vertexCount) = commandInterface.readVertices(device: device, extraVals: 3) else {
            return nil
        }
        self.vertexBufferWithColors = vertexBufferWithColors
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
        // Render vertices as a connected triangle strip, expecting vertices to alternate sides of a convex polygon.
        renderEncoder.setRenderPipelineState(colorRenderingState.getVerticesWithColorPipelineState())
        renderEncoder.setVertexBuffer(vertexBufferWithColors, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: vertexCount)
        return true
    }
}
