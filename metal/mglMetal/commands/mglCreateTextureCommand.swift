//
//  mglCreateTextureCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/3/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation
import MetalKit

class mglCreateTextureCommand : mglCommand {
    private let texture: MTLTexture
    var textureNumber: UInt32 = 0

    init(texture: MTLTexture) {
        self.texture = texture
        super.init()
    }

    init?(commandInterface: mglCommandInterface) {
        guard let incomingTexture = commandInterface.createTexture(device: mglRenderer.device) else {
            return nil
        }
        texture = incomingTexture
        super.init()
    }

    override func doNondrawingWork(
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        deg2metal: inout simd_float4x4,
        errorMessage: inout String
    ) -> Bool {
        self.textureNumber = colorRenderingState.addTexture(texture: texture)
        return true
    }
}
