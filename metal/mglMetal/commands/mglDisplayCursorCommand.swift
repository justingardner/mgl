//
//  mglDisplayCursorCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/3/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation
import MetalKit

class mglDisplayCursorCommand : mglCommand {
    // Flag to keep track of cursor state -- for the whole app.
    static var cursorHidden = false

    // Whether this is a hide (0) or show (1).
    private let displayOrHide: UInt32

    init(displayOrHide: UInt32) {
        self.displayOrHide = displayOrHide
        super.init()
    }

    init?(commandInterface: mglCommandInterface) {
        guard let displayOrHide = commandInterface.readUInt32() else {
            return nil
        }
        self.displayOrHide = displayOrHide
        super.init()
    }

    override func doNondrawingWork(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        renderer: mglRenderer2,
        deg2metal: inout simd_float4x4,
        targetPresentationTimestamp: CFTimeInterval?
    ) -> Bool {
        if displayOrHide == 0 {
            // Hide the cursor
            if !mglDisplayCursorCommand.cursorHidden {
                NSCursor.hide()
                mglDisplayCursorCommand.cursorHidden = true
            }
        }
        else {
            // Show the cursor
            if mglDisplayCursorCommand.cursorHidden {
                NSCursor.unhide()
                mglDisplayCursorCommand.cursorHidden = false
            }

        }
        return true
    }
}
