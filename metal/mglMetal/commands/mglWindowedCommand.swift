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

class mglWindowedCommand : mglCommand {
    override func doNondrawingWork(
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        deg2metal: inout simd_float4x4,
        errorMessage: inout String
    ) -> Bool {
        NSCursor.unhide()
        mglDisplayCursorCommand.cursorHidden = false

        guard let window = view.window else {
            os_log("(mglWindowedCommand) Could not get window from view, skipping windowed command.",
                   log: .default, type: .error)
            return false
        }

        if !window.styleMask.contains(.fullScreen) {
            os_log("(mglWindowedCommand) App is already windowed, skipping windowed command.",
                   log: .default, type: .info)
        } else {
            window.toggleFullScreen(nil)
        }
        return true
    }
}
