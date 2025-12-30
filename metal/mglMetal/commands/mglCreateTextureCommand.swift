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
    var textureCount: UInt32 = 0

    init(texture: MTLTexture) {
        self.texture = texture
        super.init()
    }

    init?(commandInterface: mglCommandInterface, device: MTLDevice) {
        guard let incomingTexture = commandInterface.createTexture(device: device) else {
            return nil
        }
        texture = incomingTexture
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
        textureNumber = colorRenderingState.addTexture(texture: texture)
        textureCount = colorRenderingState.getTextureCount()
        return true
    }

    override func writeQueryResults(
        logger: mglLogger,
        commandInterface : mglCommandInterface
    ) -> Bool {
        if (textureNumber < 1) {
            // A heads up that something went wrong.
            _ = commandInterface.writeDouble(data: -commandInterface.secs.get())
        }

        // A heads up that return data is on the way.
        _ = commandInterface.writeDouble(data: commandInterface.secs.get())

        // Specific return data for this command.
        _ = commandInterface.writeUInt32(data: textureNumber)
        _ = commandInterface.writeUInt32(data: textureCount)
        return true
    }
}
