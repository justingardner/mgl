//
//  mglStartStencilCreationCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/3/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation
import MetalKit

class mglSelectStencilCreationCommand : mglCommand {
    private let stencilNumber: UInt32

    init(stencilNumber: UInt32) {
        self.stencilNumber = stencilNumber
        super.init()
    }

    init?(commandInterface: mglCommandInterface) {
        guard let stencilNumber = commandInterface.readUInt32() else {
            return nil
        }
        self.stencilNumber = stencilNumber
        super.init()
    }

    override func draw(
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        deg2metal: inout simd_float4x4,
        renderEncoder: MTLRenderCommandEncoder,
        errorMessage: inout String
    ) -> Bool {
        return depthStencilState.selectStencil(view: view, renderEncoder: renderEncoder, stencilNumber: stencilNumber)
    }
}
