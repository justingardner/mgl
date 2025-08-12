//
//  mglSetRenderTargetCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/3/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation
import MetalKit

class mglSetRenderTargetCommand : mglCommand {
    let textureNumber: UInt32

    init(textureNumber: UInt32) {
        self.textureNumber = textureNumber
        super.init()
    }

    init?(commandInterface: mglCommandInterface) {
        guard let textureNumber = commandInterface.readUInt32() else {
            return nil
        }
        self.textureNumber = textureNumber
        super.init()
    }

    override func doNondrawingWork(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        deg2metal: inout simd_float4x4
    ) -> Bool {
        guard let targetTexture = colorRenderingState.getTexture(textureNumber: textureNumber) else {
            logger.info(component: "mglSetRenderTargetCommand", details: "For textureNumber \(textureNumber), choosing onscreen rendering.")
            return colorRenderingState.setOnscreenRenderingTarget()
        }

        logger.info(component: "mglSetRenderTargetCommand", details: "For textureNumber \(textureNumber), choosing offscreen rendering to texture.")
        return colorRenderingState.setRenderTarget(view: view, targetTexture: targetTexture)
    }
}
