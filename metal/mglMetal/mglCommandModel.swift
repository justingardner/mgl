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
 mglCommand factors out a pattern common to all mgl Metal commands, including drawing and non-drawing commands.
 This explicit model gives us something that we can:
    - test
    - extend
    - document
    - queue up in batches
    - gather timing around
    - potentially load as dynamic plugins

 This also gives us a way to oragnize our code better.
 The state and details of each command can live in mglCommand objects.
 Other cross-cutting details of communication, flow control, timing, and and Metal rendering
 can live elsewhere in mglCommandInterface, mglRenderer, etc.

 A change: upfront reading from the command interface or direct init(), stashing valuesin fields, separated from doing work.
 A change: stash query results first, write query results to command interface later.

 */
protocol mglCommand {
    // Commands should have no-arg init methods that we can use for testing.

    // In addition, commands must be able to init themselves from the command interface -- ie from bytes that the client sent.
    // In case this init from bytes fails, implementations are allowed to return nil.
    init?(commandInterface: mglCommandInterface)

    // How many frames left to draw for this command instance?
    // Most drawing commands would start with with framesRemaining == 1, meaning draw once and move on.
    // Drawing commands that start with framesRemaining > 1 support repeated drawing across a number of frames.
    // All commands should decrement framesRemaining each frame, with 0 indicating that drawing is done.
    // Non-drawing commands would start with framesRemaining <= 0.
    var framesRemaining: Int { get }

    // Get a chance to query and/or modify the app's state.
    // Stash any query results / references on the command instance until writeResults() is called.
    // Stashing gives us data to inspect during tests, and will keep the socket quiet during batched command runs.
    // Return true to indicate success / false for failure.
    // Update errorMessage as needed to add helpful failure info.
    func doNondrawingWork(
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        textures: inout [UInt32: MTLTexture],
        deg2metal: inout simd_float4x4,
        errorMessage: inout String
    ) -> Bool

    // Write any stashed query results to the command interface, to send them back to the client.
    // Return true to indicate success / false for failure.
    // Update errorMessage as needed to add helpful failure info.
    func writeQueryResults(commandInterface : mglCommandInterface) -> Bool

    // Do drawing during a render pass.
    // If this updates deg2metal, it must also set vertex bytes on the render encoder (usually happens before darw() is called)
    func draw(
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        textures: inout [UInt32: MTLTexture],
        deg2metal: inout simd_float4x4,
        renderEncoder: MTLRenderCommandEncoder,
        errorMessage: inout String
    ) -> Bool
}
