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

class mglGetWindowFrameInDisplayCommand : mglCommand {
    private var displayNumber: UInt32 = 0
    private var windowX: UInt32 = 0
    private var windowY: UInt32 = 0
    private var windowWidth: UInt32 = 0
    private var windowHeight: UInt32 = 0

    override func doNondrawingWork(
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        deg2metal: inout simd_float4x4,
        errorMessage: inout String
    ) -> Bool {
        guard let window = view.window else {
            os_log("(mglGetWindowFrameInDisplayCommand) Could get window from view, skipping get window frame command.",
                   log: .default, type: .error)
            return false
        }

        guard let screen = window.screen else {
            os_log("(mglGetWindowFrameInDisplayCommand) Could get screen from window, skipping get window frame command.",
                   log: .default, type: .error)
            return false
        }

        guard let screenIndex = NSScreen.screens.firstIndex(of: screen) else {
            os_log("(mglGetWindowFrameInDisplayCommand) Could get screen index from screens, skipping get window frame command.",
                   log: .default, type: .error)
            return false
        }

        // Convert 0-based screen index to Matlab's 1-based display number.
        displayNumber = UInt32(screenIndex + 1)

        // Return the position of the window relative to its screen, in pixel units not hi-res "points".
        let windowNativeFrame = screen.convertRectToBacking(window.frame)
        let screenNativeFrame = screen.convertRectToBacking(screen.frame)
        windowX = UInt32(windowNativeFrame.origin.x - screenNativeFrame.origin.x)
        windowY = UInt32(windowNativeFrame.origin.y - screenNativeFrame.origin.y)
        windowWidth = UInt32(windowNativeFrame.width)
        windowHeight = UInt32(windowNativeFrame.height)
        return true
    }

    override func writeQueryResults(commandInterface : mglCommandInterface) -> Bool {
        if displayNumber < 1 {
            _ = commandInterface.writeDouble(data: -commandInterface.secs.get())
            return false
        }

        // A heads up that return data is on the way.
        _ = commandInterface.writeDouble(data: commandInterface.secs.get())

        // Specific return data for this command.
        _ = commandInterface.writeUInt32(data: displayNumber)
        _ = commandInterface.writeUInt32(data: windowX)
        _ = commandInterface.writeUInt32(data: windowY)
        _ = commandInterface.writeUInt32(data: windowWidth)
        _ = commandInterface.writeUInt32(data: windowHeight)
        return true
    }
}
