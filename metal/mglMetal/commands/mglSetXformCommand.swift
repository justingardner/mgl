//
//  mglSetXformCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/3/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation
import MetalKit

class mglSetXformCommand : mglCommand {
    private let deg2metal: simd_float4x4

    init(deg2metal: simd_float4x4) {
        self.deg2metal = deg2metal
        super.init()
    }

    init?(commandInterface: mglCommandInterface) {
        guard let deg2metal = commandInterface.readXform() else {
            return nil
        }
        self.deg2metal = deg2metal
        super.init()
    }

    override func draw(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        deg2metal: inout simd_float4x4,
        renderEncoder: MTLRenderCommandEncoder
    ) -> Bool {
        // Update the app state to use this transform on subsequent render passes / frames.
        deg2metal = self.deg2metal

        // Update the current render pass to use the same transform on this frame.
        // Using index 1 is our convention, expected by all our vertex shaders.
        renderEncoder.setVertexBytes(&deg2metal, length: MemoryLayout<float4x4>.stride, index: 1)
        return true
    }
}
