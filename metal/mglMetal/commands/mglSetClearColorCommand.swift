//
//  mglSetClearColorCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 12/22/23.
//  Copyright © 2023 GRU. All rights reserved.
//

import Foundation
import MetalKit

class mglSetClearColorCommand : mglCommand {
    var framesRemaining: Int

    private let clearColor: MTLClearColor!

    required init?(commandInterface: mglCommandInterface) {
        guard let color = commandInterface.readColor() else {
            return nil
        }
        clearColor = MTLClearColor(red: Double(color[0]), green: Double(color[1]), blue: Double(color[2]), alpha: 1)
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
        view.clearColor = clearColor
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
