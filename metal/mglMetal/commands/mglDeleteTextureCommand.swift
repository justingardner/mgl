//
//  mglDeleteTextureCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/3/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation
import MetalKit
import OSLog

class mglDeleteTextureCommand : mglCommand {
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
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        deg2metal: inout simd_float4x4,
        errorMessage: inout String
    ) -> Bool {
        return colorRenderingState.removeTexture(textureNumber: textureNumber) != nil
    }
}
