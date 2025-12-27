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
    
    // for repeating commands, we need to keep an array of presentedTimes
    var presentedTimes: [presentedTimeHolder] = []
    
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
    
    // setUpFlushInFlight - this is used for repeating commands, because
    // the default logic assumes that a command will get only one
    // drawablePresented time - if there are multiple, we need to buffer
    // them - and assume that they may not come in order.
    func setUpFlushInFlight(renderer: mglRenderer2, drawable: MTLDrawable, commandBuffer: MTLCommandBuffer) {
        
        // create a varaible for keeping the drawable presentedTime
        let presentedTimeHolder = presentedTimeHolder()
        // and store in our array
        presentedTimes.append(presentedTimeHolder)
        
        // if we have the ability to register a callback for when
        // the drawable is presented, do that and get the presentedTime
        // from the drawable when it has been presented
        if #available(macOS 10.15.4, *) {
            drawable.addPresentedHandler { drawable in
                presentedTimeHolder.presentedTime = drawable.presentedTime
            }
        }
        else {
            // if not available, just set to current time
            presentedTimeHolder.presentedTime = renderer.secs.get()
        }
    }
}

// class to hold drawablePresentedTimes (used for repeating times, where
// we need to keep an array of them). If you want to extract thest to say
// an array of doubles represented in seconds, you could do:
// let presentedTimesSeconds: [Double] = presentedTimes.map { $0.presentedTime ?? 0.0 }
final class presentedTimeHolder {
    var presentedTime: CFTimeInterval?
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
