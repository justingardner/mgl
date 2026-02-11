//
//  mglGetTargetPresentationTimestamp.swift
//  mglMetal
//
//  Created by Justin Gardner on 2/10/26.
//  Copyright © 2026 GRU. All rights reserved.
//
import Foundation
import MetalKit

//++//++//++//++//++//++//++//++//++//++//++//++//++//++//++//++
// command to get targetPresentationTimestamp - the time that
// the next frame is scheduled to be displayed by the graphics card
//++//++//++//++//++//++//++//++//++//++//++//++//++//++//++//++
class mglGetTargetPresentationTimestampCommand : mglCommand {

    var targetPresentationTimestamp: Double = 0
    
    // direct init called for debugging
    init() {
        super.init()
    }

    // init.
    init?(commandInterface: mglCommandInterface, logger: mglLogger) {
        // call super
        super.init()
    }
    
    // Use this call (from renderer) to set the desired frame rate
    override func doNondrawingWork(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        renderer: mglRenderer2,
        deg2metal: inout simd_float4x4,
        targetPresentationTimestamp: CFTimeInterval?
    ) -> Bool {
        
        // keep targetPresentationTimestamp so we can report it back
        self.targetPresentationTimestamp = targetPresentationTimestamp ?? 0.0
        return true
    }

    override func writeQueryResults(
        logger: mglLogger,
        commandInterface : mglCommandInterface
    ) -> Bool {
        // write out the targetPresentationTimestamp
        _ = commandInterface.writeDouble(data: targetPresentationTimestamp)
        return true
    }
}

