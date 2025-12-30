//
//  mglFullscreenCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/3/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation
import MetalKit

class mglSetWindowFrameInDisplayCommand : mglCommand {
    private let displayNumber: UInt32
    private let windowX: UInt32
    private let windowY: UInt32
    private let windowWidth: UInt32
    private let windowHeight: UInt32

    init(displayNumber: UInt32, windowX: UInt32, windowY: UInt32, windowWidth: UInt32, windowHeight: UInt32) {
        self.displayNumber = displayNumber
        self.windowX = windowX
        self.windowY = windowY
        self.windowWidth = windowWidth
        self.windowHeight = windowHeight
        super.init()
    }

    init?(commandInterface: mglCommandInterface) {
        guard let displayNumber = commandInterface.readUInt32(),
              let windowX = commandInterface.readUInt32(),
              let windowY = commandInterface.readUInt32(),
              let windowWidth = commandInterface.readUInt32(),
              let windowHeight = commandInterface.readUInt32() else {
            return nil
        }
        self.displayNumber = displayNumber
        self.windowX = windowX
        self.windowY = windowY
        self.windowWidth = windowWidth
        self.windowHeight = windowHeight
        super.init()
    }

    override func doNondrawingWork(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        deg2metal: inout simd_float4x4,
        targetPresentationTimestamp: CFTimeInterval?
    ) -> Bool {
        // Convert Matlab's 1-based display number to a zero-based screen index.
        let screenIndex = displayNumber == 0 ? Array<NSScreen>.Index(0) : Array<NSScreen>.Index(displayNumber - 1)

        // Location of the chosen display AKA screen, according to the system desktop manager.
        // Units might be hi-res "points", convert to native display pixels AKA "backing" as needed.
        let screens = NSScreen.screens
        let screen = screens.indices.contains(screenIndex) ? screens[screenIndex] : screens[0]
        let screenNativeFrame = screen.convertRectToBacking(screen.frame)

        // Location of the window relative to the chosen display, in native pixels
        let x = Int(screenNativeFrame.origin.x) + Int(windowX)
        let y = Int(screenNativeFrame.origin.y) + Int(windowY)
        let windowNativeFrame = NSRect(x: x, y: y, width: Int(windowWidth), height: Int(windowHeight))

        // Location of the window in hi-res "points", or whatever, depending on system config.
        let windowScreenFrame = screen.convertRectFromBacking(windowNativeFrame)

        guard let window = view.window else {
            logger.error(component: "mglSetWindowFrameInDisplayCommand", details: "Could not get window from view, skipping set window frame command.")
            return false
        }

        if window.styleMask.contains(.fullScreen) {
            logger.info(component: "mglSetWindowFrameInDisplayCommand", details: "App is fullscreen, skipping set window frame command.")
            return false
        }

        logger.info(component: "mglSetWindowFrameInDisplayCommand", details: "Setting window to display \(displayNumber) frame \(String(describing: windowScreenFrame)).")
        window.setFrame(windowScreenFrame, display: true)
        return true
    }
}
