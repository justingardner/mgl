//
//  mglRepeatFlushCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/4/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation
import MetalKit

class mglRepeatFlushCommand : mglCommand {
    private let repeatCount: UInt32

    private var secs = mglSecs()
    private var drawTime: Double = 0.0

    init(repeatCount: UInt32, objectCount: UInt32, randomSeed: UInt32) {
        self.repeatCount = repeatCount
        super.init(framesRemaining: Int(repeatCount))
    }

    init?(commandInterface: mglCommandInterface) {
        guard let repeatCount = commandInterface.readUInt32() else {
            return nil
        }
        self.repeatCount = repeatCount
        super.init(framesRemaining: Int(repeatCount))
    }

    override func draw(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        deg2metal: inout simd_float4x4,
        targetPresentationTimestamp: CFTimeInterval?,
        renderEncoder: MTLRenderCommandEncoder
    ) -> Bool {
        // Record draw time to send back to the client.
        drawTime = secs.get()
        return true
    }

    override func writeQueryResults(
        logger: mglLogger,
        commandInterface : mglCommandInterface
    ) -> Bool {
        // Report to the client when drawing commands were finished.
        _ = commandInterface.writeDouble(data: drawTime)
        return true
    }
}
