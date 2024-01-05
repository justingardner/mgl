//
//  mglRepeatQuadsCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/4/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation
import MetalKit
import GameplayKit

class mglRepeatQuadsCommand : mglCommand {
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
        renderEncoder: MTLRenderCommandEncoder
    ) -> Bool {
        guard let device = view.device else {
            return false
        }

        // Pack a vertex buffer with quads: each has 6 vertices (two triangels) and 6 values per vertex [xyz rgb].
        let vertexCount = Int(6 * objectCount)
        let byteCount = Int(mglSizeOfFloatVertexArray(mglUInt32(vertexCount), 6))
        guard let vertexBuffer = device.makeBuffer(length: byteCount, options: .storageModeManaged) else {
            logger.error(component: "mglRepeatQuadsCommand", details: "Could not make vertex buffer of size \(byteCount)")
            return false
        }
        let bufferFloats = vertexBuffer.contents().bindMemory(to: Float32.self, capacity: vertexCount * 6)
        for quadIndex in (0 ..< objectCount) {
            let offset = Int(6 * 6 * quadIndex)
            packRandomQuad(buffer: bufferFloats, offset: offset)
        }

        // The buffer here uses storageModeManaged, to match the behavior of mglCommandInterface.
        // This means we have to tell the GPU about the modifications we just made using the CPU.
        vertexBuffer.didModifyRange(0 ..< byteCount)

        // Render vertices as triangles, two per quad, and 6 values per vertex: [xyz rgb].
        renderEncoder.setRenderPipelineState(colorRenderingState.getVerticesWithColorPipelineState())
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)

        // Record draw time to send back to the client.
        drawTime = secs.get()

        return true
    }

    // Create a random quad as the next 6 triangle vertices ([xyz rgb], so 36 elements total) of the given vertex buffer.
    private func packRandomQuad(buffer: UnsafeMutablePointer<Float32>, offset: Int) {
        // Pick four random corners of the quad, vertices 0, 1, 2, 3.
        let x0 = Float32(randomSource.nextUniform() * 2 - 1)
        let x1 = Float32(randomSource.nextUniform() * 2 - 1)
        let x2 = Float32(randomSource.nextUniform() * 2 - 1)
        let x3 = Float32(randomSource.nextUniform() * 2 - 1)
        let y0 = Float32(randomSource.nextUniform() * 2 - 1)
        let y1 = Float32(randomSource.nextUniform() * 2 - 1)
        let y2 = Float32(randomSource.nextUniform() * 2 - 1)
        let y3 = Float32(randomSource.nextUniform() * 2 - 1)

        // Pick one random color for the whole quad.
        let r = Float32(randomSource.nextUniform())
        let g = Float32(randomSource.nextUniform())
        let b = Float32(randomSource.nextUniform())

        // First triangle of the quad gets vertices, 0, 1, 2.
        buffer[offset + 0] = x0
        buffer[offset + 1] = y0
        buffer[offset + 2] = 0
        buffer[offset + 3] = r
        buffer[offset + 4] = g
        buffer[offset + 5] = b
        buffer[offset + 6] = x1
        buffer[offset + 7] = y1
        buffer[offset + 8] = 0
        buffer[offset + 9] = r
        buffer[offset + 10] = g
        buffer[offset + 11] = b
        buffer[offset + 12] = x2
        buffer[offset + 13] = y2
        buffer[offset + 14] = 0
        buffer[offset + 15] = r
        buffer[offset + 16] = g
        buffer[offset + 17] = b

        // Second triangle of the quad gets vertices, 2, 1, 3.
        buffer[offset + 18] = x2
        buffer[offset + 19] = y2
        buffer[offset + 20] = 0
        buffer[offset + 21] = r
        buffer[offset + 22] = g
        buffer[offset + 23] = b
        buffer[offset + 24] = x1
        buffer[offset + 25] = y1
        buffer[offset + 26] = 0
        buffer[offset + 27] = r
        buffer[offset + 28] = g
        buffer[offset + 29] = b
        buffer[offset + 30] = x3
        buffer[offset + 31] = y3
        buffer[offset + 32] = 0
        buffer[offset + 33] = r
        buffer[offset + 34] = g
        buffer[offset + 35] = b
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
