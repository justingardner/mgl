//
//  mglInfoCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/4/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation
import MetalKit

// structure for carrying info about displays
struct mglDisplayInfo {
    let displayID: CGDirectDisplayID
    let uuid: String
    let vendor: UInt32
    let model: UInt32
    let serialNumber: UInt32
    var widthPixels: Int
    var heightPixels: Int
    var refreshRate: Double
    var name: String = ""
}

class mglInfoCommand : mglCommand {
    var device: MTLDevice?
    var view: MTKView?
    
    // info about displays
    var currentDisplayIndex: Int = -1
    var displays: [mglDisplayInfo] = []
    
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
        
        // reinitialize variables
        currentDisplayIndex = -1
        displays.removeAll()

        guard
            let window = view.window,
            let screen = window.screen,
            let screenNumber = screen.deviceDescription[
                NSDeviceDescriptionKey("NSScreenNumber")
            ] as? NSNumber
        else {
            return true
        }
        
        // Initialize display information in case we can't retrieve it.
        let currentDisplayID = CGDirectDisplayID(screenNumber.uint32Value)
        
        // gather information about displays
        for (index, screen) in NSScreen.screens.enumerated() {
            
            guard let screenNumber = screen.deviceDescription[
                NSDeviceDescriptionKey("NSScreenNumber")
            ] as? NSNumber else {
                continue
            }

            let id = CGDirectDisplayID(screenNumber.uint32Value)
            
            // if this is the index of the current display, then keep it
            if id == currentDisplayID {
                currentDisplayIndex = index
            }

            let uuid: String
            if let cfUUID = CGDisplayCreateUUIDFromDisplayID(id)?.takeRetainedValue() {
                uuid = CFUUIDCreateString(nil, cfUUID) as String
            } else {
                uuid = ""
            }
            // get refresh rate
            var refreshRate = 0.0
            if let mode = CGDisplayCopyDisplayMode(id) {
                refreshRate = mode.refreshRate
            }
            // populate display info for this structure
            var display = mglDisplayInfo(
                displayID: id,
                uuid: uuid,
                vendor: CGDisplayVendorNumber(id),
                model: CGDisplayModelNumber(id),
                serialNumber: CGDisplaySerialNumber(id),
                widthPixels: CGDisplayPixelsWide(id),
                heightPixels: CGDisplayPixelsHigh(id),
                refreshRate: refreshRate
            )
            
            // add human readable display name
            display.name = displayName(for: display)

            displays.append(display)
        }

        return true
    }

    override func writeQueryResults(logger: mglLogger, commandInterface : mglCommandInterface) -> Bool {
        // return false if we were unable to get device and view
        guard let device, let view else {
            return false
        }
        
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

        // send number of displays
        _ = commandInterface.writeCommand(data: mglSendString)
        _ = commandInterface.writeString(data: "display.numDisplays")
        _ = commandInterface.writeCommand(data: mglSendDouble)
        _ = commandInterface.writeDouble(data: Double(displays.count))

        // send number of displays
        _ = commandInterface.writeCommand(data: mglSendString)
        _ = commandInterface.writeString(data: "display.currentDisplayIndex")
        _ = commandInterface.writeCommand(data: mglSendDouble)
        _ = commandInterface.writeDouble(data: Double(currentDisplayIndex))

        // send display information
        for (index, display) in displays.enumerated() {

            let prefix = "display\(index)."

            _ = commandInterface.writeCommand(data: mglSendString)
            _ = commandInterface.writeString(data: prefix + "uuid")
            _ = commandInterface.writeCommand(data: mglSendString)
            _ = commandInterface.writeString(data: display.uuid)

            _ = commandInterface.writeCommand(data: mglSendString)
            _ = commandInterface.writeString(data: prefix + "vendor")
            _ = commandInterface.writeCommand(data: mglSendDouble)
            _ = commandInterface.writeDouble(data: Double(display.vendor))

            _ = commandInterface.writeCommand(data: mglSendString)
            _ = commandInterface.writeString(data: prefix + "model")
            _ = commandInterface.writeCommand(data: mglSendDouble)
            _ = commandInterface.writeDouble(data: Double(display.model))

            _ = commandInterface.writeCommand(data: mglSendString)
            _ = commandInterface.writeString(data: prefix + "serialNumber")
            _ = commandInterface.writeCommand(data: mglSendDouble)
            _ = commandInterface.writeDouble(data: Double(display.serialNumber))

            _ = commandInterface.writeCommand(data: mglSendString)
            _ = commandInterface.writeString(data: prefix + "widthPixels")
            _ = commandInterface.writeCommand(data: mglSendDouble)
            _ = commandInterface.writeDouble(data: Double(display.widthPixels))

            _ = commandInterface.writeCommand(data: mglSendString)
            _ = commandInterface.writeString(data: prefix + "heightPixels")
            _ = commandInterface.writeCommand(data: mglSendDouble)
            _ = commandInterface.writeDouble(data: Double(display.heightPixels))

            _ = commandInterface.writeCommand(data: mglSendString)
            _ = commandInterface.writeString(data: prefix + "refreshRate")
            _ = commandInterface.writeCommand(data: mglSendDouble)
            _ = commandInterface.writeDouble(data: display.refreshRate)

            _ = commandInterface.writeCommand(data: mglSendString)
            _ = commandInterface.writeString(data: prefix + "name")
            _ = commandInterface.writeCommand(data: mglSendString)
            _ = commandInterface.writeString(data: display.name)
        }
        // send finished
        _ = commandInterface.writeCommand(data: mglSendFinished)

        return true
    }
}

/////////////////////////////////////////////////////////////////////
// get human readable monitor device name
/////////////////////////////////////////////////////////////////////
func displayName(for displayInfo: mglDisplayInfo) -> String {

    if let name = NSScreen.screens.first(where: {
         ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
             == displayInfo.displayID
     })?.localizedName {
         return name
     }

     return "Unknown"
}

