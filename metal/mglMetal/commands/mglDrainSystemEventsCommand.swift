//
//  mglDrainSystemEventsCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/3/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation
import MetalKit

class mglDrainSystemEventsCommand : mglCommand {
    override func doNondrawingWork(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        renderer: mglRenderer2,
        deg2metal: inout simd_float4x4,
        targetPresentationTimestamp: CFTimeInterval?
    ) -> Bool {
        guard let window = view.window else {
            logger.error(component: "mglDrainSystemEventsCommand", details: "Could not get window from view, skipping drain events command.")
            return false
        }

        var event = window.nextEvent(matching: .any)
        while (event != nil) {
            logger.info(component: "mglDrainSystemEventsCommand", details: "Processing OS event: \(String(describing: event))")
            event = window.nextEvent(matching: .any)
        }
        return true
    }
}
