//
//  mglCommandModel.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 6/15/22.
//  Copyright © 2022 GRU. All rights reserved.
//

import Foundation
import MetalKit

/*
 mglCommand factors out a pattern common to all mgl Metal commands.
 */
class mglCommand {
    // Here is where mglCommandInterface and mglRenderer can record and report what happened to this command.
    var results = mglCommandResults()

    // How many frames left to draw for this command instance?
    // Most drawing commands would start with with framesRemaining == 1, meaning draw once and move on.
    // Drawing commands that start with framesRemaining > 1 support repeated drawing across a number of frames.
    // mglRenderer decrements framesRemaining after drawing each fram.
    // Non-drawing commands would start with framesRemaining <= 0.
    var framesRemaining: Int = 0

    // Each command shoud provide two ways to init():
    //  - directly in memory, for use during tests
    //  - by reading from an mglCommandInterface and/or writing to an MTLDevice
    // The second one works with a connected client and is allowed allowed to fail and return nil.
    // Both inits should call up to this as "super.init()" to initialize framesRemaining.
    init(framesRemaining: Int = 0) {
        self.framesRemaining = framesRemaining
    }

    // Get a chance to query and/or modify the app's state.
    // Stash any query results / references on the command instance until writeResults() is called.
    // Stashing gives us data to inspect during tests, and will keep the socket quiet during batched command runs.
    // Return true to indicate success / false for failure.
    func doNondrawingWork(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        deg2metal: inout simd_float4x4
    ) -> Bool {
        return true
    }

    // Write any stashed query results to the command interface, to send them back to the client.
    // Return true to indicate success / false for failure.
    func writeQueryResults(
        logger: mglLogger,
        commandInterface : mglCommandInterface
    ) -> Bool {
        return true
    }

    // Do drawing during a render pass.
    func draw(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        deg2metal: inout simd_float4x4,
        renderEncoder: MTLRenderCommandEncoder
    ) -> Bool {
        return true
    }
}

/*
 Holder for status and timing around each command, to be set by mglCommandInterface and mglRenderer.
 */
struct mglCommandResults {
    var commandCode: mglCommandCode = mglUnknownCommand
    var success: Bool = false
    var ackTime: Double = 0.0
    var processedTime: Double = 0.0
    var vertexStart: Double = 0.0
    var vertexEnd: Double = 0.0
    var fragmentStart: Double = 0.0
    var fragmentEnd: Double = 0.0
    var drawableAcquired: Double = 0.0
    var drawablePresented: Double = 0.0
}
