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
    private let clearColor: MTLClearColor!

    init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        clearColor = MTLClearColor(red: red, green: green, blue: blue, alpha: 1.0)
        super.init(framesRemaining: 1)
    }

    init?(commandInterface: mglCommandInterface) {
        guard let color = commandInterface.readColor() else {
            return nil
        }
        clearColor = MTLClearColor(red: Double(color[0]), green: Double(color[1]), blue: Double(color[2]), alpha: 1)
        super.init(framesRemaining: 1)
    }

    override func doNondrawingWork(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        deg2metal: inout simd_float4x4
    ) -> Bool {
        view.clearColor = clearColor
        return true
    }
}
