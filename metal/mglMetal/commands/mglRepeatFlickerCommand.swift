//
//  mglRepeatFlickerCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/4/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation
import MetalKit
import GameplayKit

class mglRepeatFlickerCommand : mglCommand {
    private let repeatCount: UInt32
    private let randomSeed: UInt32
    private let randomSource: GKMersenneTwisterRandomSource

    init(repeatCount: UInt32, randomSeed: UInt32) {
        self.repeatCount = repeatCount
        self.randomSeed = randomSeed
        self.randomSource = GKMersenneTwisterRandomSource(seed: UInt64(randomSeed))
        super.init(framesRemaining: Int(repeatCount))
    }

    init?(commandInterface: mglCommandInterface) {
        guard let repeatCount = commandInterface.readUInt32(),
              let randomSeed = commandInterface.readUInt32() else {
            return nil
        }
        self.repeatCount = repeatCount
        self.randomSeed = randomSeed
        self.randomSource = GKMersenneTwisterRandomSource(seed: UInt64(randomSeed))
        super.init(framesRemaining: Int(repeatCount))
    }

    override func draw(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        deg2metal: inout simd_float4x4,
        renderEncoder: MTLRenderCommandEncoder
    ) -> Bool {
        // Choose a new, random color for the view to use on the next render pass.
        let r = Double(randomSource.nextUniform())
        let g = Double(randomSource.nextUniform())
        let b = Double(randomSource.nextUniform())
        let clearColor = MTLClearColor(red: r, green: g, blue: b, alpha: 1)
        view.clearColor = clearColor

        return true
    }
}
