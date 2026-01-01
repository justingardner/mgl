//
//  mglInfoCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/4/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation
import MetalKit

class mglInfoCommand : mglCommand {
    var device: MTLDevice!
    var view: MTKView!

    override func doNondrawingWork(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        renderer: mglRenderer2,
        deg2metal: inout simd_float4x4,
        targetPresentationTimestamp: CFTimeInterval?
    ) -> Bool {
        // Stash references to the current app view and device for readout, below.
        // This is a little unusual compared to other commands.
        guard let device = view.device else {
            return false
        }
        self.device = device
        self.view = view
        return true
    }

    override func writeQueryResults(logger: mglLogger, commandInterface : mglCommandInterface) -> Bool {
        // send GPU name
        _ = commandInterface.writeCommand(data: mglSendString)
        _ = commandInterface.writeString(data: "gpu.name")
        _ = commandInterface.writeCommand(data: mglSendString)
        _ = commandInterface.writeString(data: device.name)

        // send GPU registryID
        _ = commandInterface.writeCommand(data: mglSendString)
        _ = commandInterface.writeString(data: "gpu.registryID")
        _ = commandInterface.writeCommand(data: mglSendDouble)
        _ = commandInterface.writeDouble(data: Double(device.registryID))

        // send currentAllocatedSize
        _ = commandInterface.writeCommand(data: mglSendString)
        _ = commandInterface.writeString(data: "gpu.currentAllocatedSize")
        _ = commandInterface.writeCommand(data: mglSendDouble)
        _ = commandInterface.writeDouble(data: Double(device.currentAllocatedSize))

        // send recommendedMaxWorkingSetSize
        _ = commandInterface.writeCommand(data: mglSendString)
        _ = commandInterface.writeString(data: "gpu.recommendedMaxWorkingSetSize")
        _ = commandInterface.writeCommand(data: mglSendDouble)
        _ = commandInterface.writeDouble(data: Double(device.recommendedMaxWorkingSetSize))

        // send hasUnifiedMemory
        _ = commandInterface.writeCommand(data: mglSendString)
        _ = commandInterface.writeString(data: "gpu.hasUnifiedMemory")
        _ = commandInterface.writeCommand(data: mglSendDouble)
        _ = commandInterface.writeDouble(data: device.hasUnifiedMemory ? 1.0 : 0.0)

        // send maxTransferRate
        _ = commandInterface.writeCommand(data: mglSendString)
        _ = commandInterface.writeString(data: "gpu.maxTransferRate")
        _ = commandInterface.writeCommand(data: mglSendDouble)
        _ = commandInterface.writeDouble(data: Double(device.maxTransferRate))

        // send minimumLinearTextureAlignment
        _ = commandInterface.writeCommand(data: mglSendString)
        _ = commandInterface.writeString(data: "gpu.minimumTextureBufferAlignment")
        _ = commandInterface.writeCommand(data: mglSendDouble)
        _ = commandInterface.writeDouble(data: Double(device.minimumTextureBufferAlignment(for: .rgba32Float)))

        // send minimumLinearTextureAlignment
        _ = commandInterface.writeCommand(data: mglSendString)
        _ = commandInterface.writeString(data: "gpu.minimumLinearTextureAlignment")
        _ = commandInterface.writeCommand(data: mglSendDouble)
        _ = commandInterface.writeDouble(data: Double(device.minimumLinearTextureAlignment(for: .rgba32Float)))

        _ = commandInterface.writeCommand(data: mglSendString)
        _ = commandInterface.writeString(data: "view.colorPixelFormat")
        _ = commandInterface.writeCommand(data: mglSendDouble)
        _ = commandInterface.writeDouble(data: Double(view.colorPixelFormat.rawValue))

        _ = commandInterface.writeCommand(data: mglSendString)
        _ = commandInterface.writeString(data: "view.colorPixelFormatString")
        _ = commandInterface.writeCommand(data: mglSendString)
        switch view.colorPixelFormat {
        case MTLPixelFormat.bgra8Unorm: _ = commandInterface.writeString(data: "bgra8Unorm")
        case MTLPixelFormat.bgra8Unorm_srgb: _ = commandInterface.writeString(data: "bgra8Unorm_srgb")
        case MTLPixelFormat.rgba16Float: _ = commandInterface.writeString(data: "rgba16Float")
        case MTLPixelFormat.rgb10a2Unorm: _ = commandInterface.writeString(data: "rgb10a2Unorm")
        case MTLPixelFormat.bgr10a2Unorm: _ = commandInterface.writeString(data: "bgr10a2Unorm")
        default: _ = commandInterface.writeString(data: "Unknown")
        }

        _ = commandInterface.writeCommand(data: mglSendString)
        _ = commandInterface.writeString(data: "view.clearColor")
        _ = commandInterface.writeCommand(data: mglSendDoubleArray)
        let colorArray: [Double] = [Double(view.clearColor.red),Double(view.clearColor.green),Double(view.clearColor.blue),Double(view.clearColor.alpha)]
        _ = commandInterface.writeDoubleArray(data: colorArray)

        _ = commandInterface.writeCommand(data: mglSendString)
        _ = commandInterface.writeString(data: "view.drawableSize")
        _ = commandInterface.writeCommand(data: mglSendDoubleArray)
        let drawableSize: [Double] = [Double(view.drawableSize.width), Double(view.drawableSize.height)]
        _ = commandInterface.writeDoubleArray(data: drawableSize)

        // send finished
        _ = commandInterface.writeCommand(data: mglSendFinished)

        return true
    }
}
