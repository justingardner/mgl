//
//  mglFlushCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 12/22/23.
//  Copyright © 2023 GRU. All rights reserved.
//

import Foundation
import MetalKit

class mglFlushCommand : mglCommand {
    var framesRemaining: Int

    required init?(commandInterface: mglCommandInterface) {
        framesRemaining = 1
    }

    func doNondrawingWork(
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        textures: inout [UInt32 : MTLTexture],
        deg2metal: inout simd_float4x4,
        errorMessage: inout String
    ) -> Bool {
        return true
    }

    func writeQueryResults(commandInterface: mglCommandInterface) -> Bool {
        return true
    }

    func draw(
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        textures: inout [UInt32 : MTLTexture],
        deg2metal: inout simd_float4x4,
        renderEncoder: MTLRenderCommandEncoder,
        errorMessage: inout String
    ) -> Bool {
        return true
    }
}
