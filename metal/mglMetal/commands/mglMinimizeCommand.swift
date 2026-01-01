//
//  mglMinimizeCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/4/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation
import MetalKit

class mglMinimizeCommand : mglCommand {
    private let minimizeOrRestore: UInt32

    init(minimizeOrRestore: UInt32) {
        self.minimizeOrRestore = minimizeOrRestore
        super.init()
    }

    init?(commandInterface: mglCommandInterface) {
        // Get whether this is a minimize (0) or restore (1)
        guard let minimizeOrRestore = commandInterface.readUInt32() else {
            return nil
        }
        self.minimizeOrRestore = minimizeOrRestore
        super.init()
    }

    override func doNondrawingWork(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        renderer: mglRenderer2,
        deg2metal: inout simd_float4x4,
        targetPresentationTimestamp: CFTimeInterval?
    ) -> Bool {
        if minimizeOrRestore == 0 {
            // minimize
            view.window?.miniaturize(nil)
        } else {
            // restore
            view.window?.deminiaturize(nil)
        }
        return true
    }
}
