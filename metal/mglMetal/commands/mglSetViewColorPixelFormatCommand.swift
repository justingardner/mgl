//
//  mglSetViewColorPixelFormatCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/3/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation
import MetalKit

class mglSetViewColorPixelFormatCommand : mglCommand {
    private var format: MTLPixelFormat = .bgra8Unorm

    init(format: MTLPixelFormat) {
        self.format = format
        super.init()
    }

    init?(commandInterface: mglCommandInterface) {
        guard let formatIndex = commandInterface.readUInt32() else {
            return nil
        }
        switch formatIndex {
        case 0: format = .bgra8Unorm
        case 1: format = .bgra8Unorm_srgb
        case 2: format = .rgba16Float
        case 3: format = .rgb10a2Unorm
        case 4: format = .bgr10a2Unorm
        default: format = .bgra8Unorm
        }
        super.init()
    }

    override func doNondrawingWork(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        deg2metal: inout simd_float4x4
    ) -> Bool {
        return colorRenderingState.setOnscreenColorPixelFormat(view: view, pixelFormat: format)
    }
}
