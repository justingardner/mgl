//
//  mglReadTextureCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/3/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation
import MetalKit
import OSLog

class mglReadTextureCommand : mglCommand {
    let textureNumber: UInt32
    private var texture: MTLTexture?

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
        guard let existingTexture = colorRenderingState.getTexture(textureNumber: textureNumber) else {
            return false
        }
        texture = existingTexture
        return true
    }

    override func writeQueryResults(commandInterface : mglCommandInterface) -> Bool {
        guard let unboxedTexture = texture else {
            os_log("(mglReadTextureCommand) Unable to read null texture",
                   log: .default, type: .error)
            _ = commandInterface.writeDouble(data: -commandInterface.secs.get())
            return false
        }

        guard let buffer = unboxedTexture.buffer else {
            os_log("(mglReadTextureCommand) Unable to access buffer of texture %{public}@",
                   log: .default, type: .error, String(describing: unboxedTexture))
            _ = commandInterface.writeDouble(data: -commandInterface.secs.get())
            return false
        }

        // A heads up that return data is on the way.
        _ = commandInterface.writeDouble(data: commandInterface.secs.get())

        // Specific return data for this command.
        let imageRowByteCount = Int(mglSizeOfFloatRgbaTexture(mglUInt32(unboxedTexture.width), 1))
        _ = commandInterface.writeUInt32(data: mglUInt32(unboxedTexture.width))
        _ = commandInterface.writeUInt32(data: mglUInt32(unboxedTexture.height))
        let totalByteCount = commandInterface.imageRowsFromBuffer(
            buffer: buffer,
            imageRowByteCount: imageRowByteCount,
            alignedRowByteCount: unboxedTexture.bufferBytesPerRow,
            rowCount: unboxedTexture.height
        )
        return totalByteCount == imageRowByteCount * unboxedTexture.height
    }
}
