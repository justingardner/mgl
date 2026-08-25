//
//  mglSetTextRenderingParametersCommand.swift
//  mglMetal
//
//  Created by Justin Gardner on 8/24/2026.
//  Copyright © 2026 GRU.
//

import Foundation
import MetalKit

class mglSetTextRenderingParametersCommand: mglCommand {
    private let parameters: mglTextRenderingParameters

    init(parameters: mglTextRenderingParameters) {
        self.parameters = parameters
        super.init()
    }

    // Read a complete replacement set of text-rendering parameters.
    //
    // Incoming command payload:
    //   String  fontName
    //   Float   fontSize
    //   UInt32  paddingPixels
    //   Float   foregroundRed
    //   Float   foregroundGreen
    //   Float   foregroundBlue
    //   Float   foregroundAlpha
    //   Float   backgroundRed
    //   Float   backgroundGreen
    //   Float   backgroundBlue
    //   Float   backgroundAlpha
    init?(commandInterface: mglCommandInterface) {
        let fontName = commandInterface.readString()

        guard let fontSize = commandInterface.readFloat(),
              let paddingPixels = commandInterface.readUInt32(),
              let foregroundRed = commandInterface.readFloat(),
              let foregroundGreen = commandInterface.readFloat(),
              let foregroundBlue = commandInterface.readFloat(),
              let foregroundAlpha = commandInterface.readFloat(),
              let backgroundRed = commandInterface.readFloat(),
              let backgroundGreen = commandInterface.readFloat(),
              let backgroundBlue = commandInterface.readFloat(),
              let backgroundAlpha = commandInterface.readFloat() else {
            return nil
        }

        self.parameters = mglTextRenderingParameters(
            fontName: fontName,
            fontSize: fontSize,
            paddingPixels: paddingPixels,
            foregroundRed: foregroundRed,
            foregroundGreen: foregroundGreen,
            foregroundBlue: foregroundBlue,
            foregroundAlpha: foregroundAlpha,
            backgroundRed: backgroundRed,
            backgroundGreen: backgroundGreen,
            backgroundBlue: backgroundBlue,
            backgroundAlpha: backgroundAlpha
        )

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
        return colorRenderingState.setTextRenderingParameters(
            parameters: parameters
        )
    }
}
