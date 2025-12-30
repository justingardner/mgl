//
//  mglRepeatDotsCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/4/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation
import MetalKit
import GameplayKit

class mglRepeatDotsCommand : mglCommand {
    private let repeatCount: UInt32
    private let objectCount: UInt32
    private let randomSeed: UInt32
    private let randomSource: GKMersenneTwisterRandomSource

    private var secs = mglSecs()
    private var drawTime: Double = 0.0

    init(repeatCount: UInt32, objectCount: UInt32, randomSeed: UInt32) {
        self.repeatCount = repeatCount
        self.objectCount = objectCount
        self.randomSeed = randomSeed
        self.randomSource = GKMersenneTwisterRandomSource(seed: UInt64(randomSeed))
        super.init(framesRemaining: Int(repeatCount))
    }

    init?(commandInterface: mglCommandInterface) {
        guard let repeatCount = commandInterface.readUInt32(),
              let objectCount = commandInterface.readUInt32(),
              let randomSeed = commandInterface.readUInt32() else {
            return nil
        }
        self.repeatCount = repeatCount
        self.objectCount = objectCount
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
        targetPresentationTimestamp: CFTimeInterval?,
        renderEncoder: MTLRenderCommandEncoder
    ) -> Bool {
        // Pack a vertex buffer with dots: each has 1 vertex and 11 values per vertex vertex: [xyz rgba wh isRound borderSize].
        let vertexCount = Int(objectCount)
        let byteCount = Int(mglSizeOfFloatVertexArray(mglUInt32(vertexCount), 11))
        guard let vertexBuffer = view.device?.makeBuffer(length: byteCount, options: .storageModeManaged) else {
            logger.error(component: "mglRepeatDotsCommand", details: "Could not make vertex buffer of size \(byteCount)")
            return false
        }
        let bufferFloats = vertexBuffer.contents().bindMemory(to: Float32.self, capacity: vertexCount)
        for dotIndex in (0 ..< vertexCount) {
            let offset = Int(11 * dotIndex)
            packRandomDot(buffer: bufferFloats, offset: offset)
        }

        // Draw all the vertices as points with 11 values per vertex: [xyz rgba wh isRound borderSize].
        renderEncoder.setRenderPipelineState(colorRenderingState.getDotsPipelineState())
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertexCount)

        // Record draw time to send back to the client.
        drawTime = secs.get()

        return true
    }

    // Create a random dot as the next vertex, with 11 elements per vertex, of the given vertex buffer.
    private func packRandomDot(buffer: UnsafeMutablePointer<Float32>, offset: Int) {
        // xyz
        buffer[offset + 0] = Float32(randomSource.nextUniform() * 2 - 1)
        buffer[offset + 1] = Float32(randomSource.nextUniform() * 2 - 1)
        buffer[offset + 2] = 0

        // rgba
        buffer[offset + 3] = Float32(randomSource.nextUniform())
        buffer[offset + 4] = Float32(randomSource.nextUniform())
        buffer[offset + 5] = Float32(randomSource.nextUniform())
        buffer[offset + 6] = 1
        
        // wh
        buffer[offset + 7] = 1
        buffer[offset + 8] = 1

        // round
        buffer[offset + 9] = 0

        // border size
        buffer[offset + 10] = 0
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
