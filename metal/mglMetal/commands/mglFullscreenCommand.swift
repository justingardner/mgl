//
//  mglFullscreenCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/3/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation
import MetalKit
import OSLog

class mglFullscreenCommand : mglCommand {
    override func doNondrawingWork(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        deg2metal: inout simd_float4x4
    ) -> Bool {
        guard let window = view.window else {
            logger.error(component: "mglFullscreenCommand", details: "Could not get window from view, skipping fullscreen command.")
            return false
        }

        if window.styleMask.contains(.fullScreen) {
            logger.info(component: "mglFullscreenCommand", details: " App is already fullscreen, skipping fullscreen command.")
        } else {
            window.toggleFullScreen(nil)
            NSCursor.hide()
            mglDisplayCursorCommand.cursorHidden = true
        }
        return true
    }
}
