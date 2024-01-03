//
//  mglStartStencilCreationCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/3/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation
import MetalKit

class mglFinishStencilCreationCommand : mglCommand {
    override func doNondrawingWork(
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        deg2metal: inout simd_float4x4,
        errorMessage: inout String
    ) -> Bool {
        return depthStencilState.finishStencilCreation(view: view)
    }
}
