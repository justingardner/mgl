//
//  mglFullscreenCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/3/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation
import MetalKit

class mglWindowedCommand : mglCommand {
    override func doNondrawingWork(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        deg2metal: inout simd_float4x4,
        targetPresentationTimestamp: CFTimeInterval?
    ) -> Bool {
        NSCursor.unhide()
        mglDisplayCursorCommand.cursorHidden = false

        guard let window = view.window else {
            logger.error(component: "mglWindowedCommand", details: "Could not get window from view, skipping windowed command.")
            return false
        }

        if !window.styleMask.contains(.fullScreen) {
            logger.info(component: "mglWindowedCommand", details: "App is already windowed, skipping windowed command.")
        } else {
            window.toggleFullScreen(nil)
        }
        return true
    }
}
