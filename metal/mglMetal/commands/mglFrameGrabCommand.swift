//
//  mglFrameGrabCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/4/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation
import MetalKit

class mglFrameGrabCommand : mglCommand {
    private var width: Int = 0
    private var height: Int = 0
    private var dataPointer: UnsafeMutablePointer<Float>? = nil

    override func doNondrawingWork(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        renderer: mglRenderer2,
        deg2metal: inout simd_float4x4,
        targetPresentationTimestamp: CFTimeInterval?
    ) -> Bool {
        // grab from from the currentColorRenderingTarget. Note that
        // this will return (0,0,nil) if the current target is the screen
        // as it is not implemented (and might be hard/impossible?) to get
        // the bytes from that. So, this only works if the current target
        // is a texture (which is set by mglMetalSetRenderTarget
        (width, height, dataPointer) = colorRenderingState.frameGrab()
        return dataPointer != nil
    }

    override func writeQueryResults(
        logger: mglLogger,
        commandInterface : mglCommandInterface
    ) -> Bool {
        // write out the width and height
        _ = commandInterface.writeUInt32(data: UInt32(width))
        _ = commandInterface.writeUInt32(data: UInt32(height))
        if dataPointer != nil {
            // convert the pointer back into an array
            let floatArray = Array(UnsafeBufferPointer(start: dataPointer, count: width * height * 4))

            // write the array
            _ = commandInterface.writeFloatArray(data: floatArray)

            // free the data
            dataPointer?.deallocate()
            return true
        }
        else {
            return false
        }
    }
}
