//
//  mglCreateTextTextureCommand.swift
//  mglMetal
//
//  Created by Justin Gardner on 8/24/2026.
//  Copyright © 2026 GRU.
//

import Foundation
import MetalKit

class mglCreateTextTextureCommand: mglCommand {
    // The UTF-8 text received from the client.
    private let text: String

    // Results populated when doNondrawingWork() renders and registers the texture.
    private var texture: MTLTexture?
    private var textureWidth: UInt32 = 0
    private var textureHeight: UInt32 = 0

    private var textureNumber: UInt32 = 0
    private var textureCount: UInt32 = 0

    init(text: String) {
        self.text = text
        super.init()
    }

    // Receive only the text itself from the client.
    //
    // Rendering parameters are deliberately not received here.  They are stored
    // persistently in mglColorRenderingState and read later, during execution.
    init(commandInterface: mglCommandInterface) {
        self.text = commandInterface.readString()
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
        logger.error(
            component: "mglCreateTextTextureCommand",
            details: "Starting text texture creation for '\(text)'."
        )

        guard let device = view.device else {
            logger.error(
                component: "mglCreateTextTextureCommand",
                details: "Cannot create text texture because view.device is nil."
            )
            return false
        }

        let parameters = colorRenderingState.getTextRenderingParameters()

        logger.error(
            component: "mglCreateTextTextureCommand",
            details: "Rendering '\(text)' with font '\(parameters.fontName)' at size \(parameters.fontSize)."
        )

        guard let renderedText = mglTextTextureRenderer.makeTexture(
            device: device,
            text: text,
            parameters: parameters,
            logger: logger
        ) else {
            logger.error(
                component: "mglCreateTextTextureCommand",
                details: "mglTextTextureRenderer failed for '\(text)'."
            )
            return false
        }

        logger.error(
            component: "mglCreateTextTextureCommand",
            details: "Rendered text texture is \(renderedText.width) x \(renderedText.height)."
        )

        texture = renderedText.texture
        textureWidth = renderedText.width
        textureHeight = renderedText.height

        textureNumber = colorRenderingState.addTexture(
            texture: renderedText.texture
        )

        textureCount = colorRenderingState.getTextureCount()

        logger.error(
            component: "mglCreateTextTextureCommand",
            details: "Registered text texture \(textureNumber), total textures \(textureCount)."
        )

        return textureNumber > 0
    }

    override func writeQueryResults(
        logger: mglLogger,
        commandInterface: mglCommandInterface
    ) -> Bool {
        guard textureNumber > 0 else {
            logger.error(
                component: "mglCreateTextTextureCommand",
                details: "Cannot report text texture results because texture creation failed."
            )

            // Standard mgl failure indication.
            _ = commandInterface.writeDouble(
                data: -commandInterface.secs.get()
            )

            return false
        }

        // Standard mgl indication that command-specific result data follows.
        _ = commandInterface.writeDouble(
            data: commandInterface.secs.get()
        )

        // Text texture size in pixels.  Python needs these to create its
        // pglImageInstance-like wrapper and calculate display placement.
        _ = commandInterface.writeUInt32(data: textureWidth)
        _ = commandInterface.writeUInt32(data: textureHeight)

        // Normal user texture registry information.
        _ = commandInterface.writeUInt32(data: textureNumber)
        _ = commandInterface.writeUInt32(data: textureCount)

        return true
    }
}
