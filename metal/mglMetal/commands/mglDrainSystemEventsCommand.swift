//
//  mglDrainSystemEventsCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/3/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation
import MetalKit
import OSLog

class mglDrainSystemEventsCommand : mglCommand {
    override func doNondrawingWork(
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        deg2metal: inout simd_float4x4,
        errorMessage: inout String
    ) -> Bool {
        guard let window = view.window else {
            os_log("(mglDrainSystemEventsCommand) Could not get window from view, skipping drain events command.",
                   log: .default, type: .error)
            return false
        }

        var event = window.nextEvent(matching: .any)
        while (event != nil) {
            os_log("(mglDrainSystemEventsCommand) Processing OS event: %{public}@",
                   log: .default, type: .info, String(describing: event))
            event = window.nextEvent(matching: .any)
        }
        return true
    }
}
