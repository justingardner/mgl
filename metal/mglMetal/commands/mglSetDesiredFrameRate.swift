//
//  mglSetDesiredFrameRate.swift
//  mglMetal
//
//  Created by Justin Gardner on 1/1/26.
//  Copyright © 2026 GRU. All rights reserved.
//
import Foundation
import MetalKit

//++//++//++//++//++//++//++//++//++//++//++//++//++//++//++//++
// command to set desired frame rate
//++//++//++//++//++//++//++//++//++//++//++//++//++//++//++//++
class mglSetDesiredFrameRateCommand : mglCommand {

    var desiredFrameRate: UInt32 = 0
    
    // direct init called for debugging
    init() {
        super.init()
    }

    // init.
    init?(commandInterface: mglCommandInterface, logger: mglLogger) {
        
        // Read the desired frame rate from commandInterface
        guard let desiredFrameRate = commandInterface.readUInt32() else {
            return nil
        }
        // Display what is happening in log
        logger.info(component: "mgSetDesiredFrameRateCommand", details: "Setting desired frame rate of: \(desiredFrameRate)")
        self.desiredFrameRate = desiredFrameRate
        
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
        // check to see if we are running CAMetalDisplayLink
        guard #available(macOS 14.0, *), let displayLink = renderer.metalDisplayLink
        else {
            // No 14.0 or displayLink, so we are using the view to update
            view.preferredFramesPerSecond = Int(desiredFrameRate)
            return true
        }

        // Set the preferred frame Rate for CAMetalDisplayLink
        displayLink.preferredFrameRateRange = CAFrameRateRange(minimum: Float(desiredFrameRate), maximum: Float(desiredFrameRate), preferred: Float(desiredFrameRate))
        return true
    }

}
