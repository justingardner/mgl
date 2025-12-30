//
//  mglStartStencilCreationCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/3/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation
import MetalKit

class mglStartStencilCreationCommand : mglCommand {
    private let stencilNumber: UInt32
    private let isInverted: Bool

    init(stencilNumber: UInt32, isInverted: Bool) {
        self.stencilNumber = stencilNumber
        self.isInverted = isInverted
        super.init()
    }

    init?(commandInterface: mglCommandInterface) {
        guard let stencilNumber = commandInterface.readUInt32(),
              let isInverted = commandInterface.readUInt32() else {
            return nil
        }
        self.stencilNumber = stencilNumber
        self.isInverted = isInverted != 0
        super.init()
    }

    override func doNondrawingWork(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        deg2metal: inout simd_float4x4,
        targetPresentationTimestamp: CFTimeInterval?
    ) -> Bool {
        return depthStencilState.startStencilCreation(view: view, stencilNumber: stencilNumber, isInverted: isInverted)
    }
}
