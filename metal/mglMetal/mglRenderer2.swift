//
//  mglRenderer2.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 12/22/23.
//  Copyright © 2023 GRU. All rights reserved.
//

import Foundation
import MetalKit

class mglRenderer2: NSObject {
    private let logger: mglLogger

    // GPU Device
    private let device: MTLDevice

    // commandQueue which tells the device what to do
    static var commandQueue: MTLCommandQueue!

    // library holds compiled vertex and fragment shader programs
    let library: MTLLibrary!

    // command interface communicates with the client process like Matlab
    let commandInterface : mglCommandInterface

    // Keep track of depth and stencil state, like creating vs applying a stencil, and which stencil.
    let depthStencilState: mglDepthStencilState

    // Keep track of color rendering state, like oncreen vs offscreen texture, and which texture.
    let colorRenderingState: mglColorRenderingState

    // keeps coordinate xform
    var deg2metal = matrix_identity_float4x4

    // a collection of user-managed textures to render to and/or blt to screen
    var textureSequence = UInt32(1)
    var textures : [UInt32: MTLTexture] = [:]

    // utility to get system nano time
    let secs = mglSecs()

    init(logger: mglLogger, metalView: MTKView, commandInterface: mglCommandInterface) {
        self.logger = logger
        self.commandInterface = commandInterface

        // Initialize the GPU device.
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("GPU not available")
        }
        self.device = device
        metalView.device = device

        // Initialize the low-level Metal command queue.
        mglRenderer.commandQueue = device.makeCommandQueue()!

        // Create a library for storing the shaders.
        library = device.makeDefaultLibrary()

        // Inititialize 8 stencil planes and depth testing.
        // Confusingly, some parts of the Metal API treat these as one feature,
        // while other parts treat depth and stenciling as separate features.
        metalView.depthStencilPixelFormat = .depth32Float_stencil8
        metalView.clearDepth = 1.0
        depthStencilState = mglDepthStencilState(logger: logger, device: device)

        // Initialize color rendering, default to onscreen.
        // Default gray clear color applies to onscreen and/or offscreen texture.
        metalView.clearColor = MTLClearColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        colorRenderingState = mglColorRenderingState(logger: logger, device: device, library: library, view: metalView)

        // init the super class
        super.init()

        // Tell the view that this class will be used as the delegate for draw() and resize() callbacks.
        metalView.delegate = self

        logger.info(component: "mglRenderer2", details: "Init OK.")
    }
}


extension mglRenderer2: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        logger.info(component: "mglRenderer2", details: "drawableSizeWillChange \(String(describing: size))")
    }

    // We expect the view to be configured for "Timed updates" (the default),
    // which is the traditional way of running once per "video frame", "screen refresh", etc.
    // as described here:
    //   https://developer.apple.com/documentation/metalkit/mtkview?language=objc
    func draw(in view: MTKView) {
        // Using autoreleasepool lets us attempt to release system resources like the "drawable" as soon as we're done.
        // Apple's guidance is to do this once per frame, rather than letting it happen lazily at some later time.
        //  https://developer.apple.com/library/archive/documentation/3DDrawing/Conceptual/MTLBestPracticesGuide/Drawables.html
        autoreleasepool {
            render(in: view)
        }
    }

    private func render(in view: MTKView) {
        // Report to the client about any commands that were completed on the previous frame.
        // TODO: this may change when we incorporate the counters API.
        commandInterface.reportDoneLater()

        // Get the next command from the command interface.
        // If there isn't any just return and we don't need to do anything during this frame.
        if !commandInterface.commandWaiting() {
            return
        }
        guard var command = commandInterface.awaitNext(device: device) else {
            return
        }

        // Let the command do non-drawing work, like getting and setting the state of the app.
        let nondrawingSuccess = command.doNondrawingWork(
            logger: logger,
            view: view,
            depthStencilState: depthStencilState,
            colorRenderingState: colorRenderingState,
            deg2metal: &deg2metal
        )

        // On failure, exit right away.
        if !nondrawingSuccess {
            commandInterface.done(command: command, success: false)
            return
        }

        // On success, check whether the command also wants to draw something.
        if command.framesRemaining <= 0 {
            // No "frames remaining" means that this nondrawing command is all done.
            commandInterface.done(command: command)
            return
        }

        // Yes "frames remaining" means that this command wants to draw something.  So:
        //  1. Set up a Metal rendering pass.
        //  2. Enter a tight loop to accept more commands in the same frame.
        //  3. Present the frame representing all commands until "flush".

        //
        // 1. Set up a Metal rendering pass.
        //

        // This call to view.currentDrawable accesses an expensive system resource, the "drawable".
        // Normally this is fast and not a problem.
        // But we've seen it get slow when using large amounts of video memory.
        // For example when we have 30 full-screen-sized textures loaded at once.
        // For rgba Float32 textures, 30 of these can take up about a GB of memory.
        // In this case the call duration is sometimes <1ms, sometimes ~7ms, sometimes even ~14 ms.
        // It's not entirely consistent, but the durations seem to come in runs that last for many frames or several seconds.
        // Even when in a run of ~14ms durations, we don't necessarily drop more frames than usual.
        // When we do drop a frame, this seems to kick off a new run with a different call duration, for a while.
        // We may be seeing some blocking/synchronizing on the expensive "drawable" resource.
        // We seem to be already following the guidance about the "drawable" as discussed in Apple docs:
        //   https://developer.apple.com/documentation/metalkit/mtkview
        //   https://developer.apple.com/documentation/quartzcore/cametallayer#3385893
        //   https://developer.apple.com/library/archive/documentation/3DDrawing/Conceptual/MTLBestPracticesGuide/Drawables.html
        // In particular, we're doing our rendering work inside an autoreleasepool {} block,
        // and we're not acquiring the drawable until we really are about to render a frame.
        // So, are we just finding out how to tax the system and seeing what happens in that case?
        // Does the system "know best" and we are blocking/synchronizing as expected?
        // Or is there somethign else we can do about these long call durations?
        guard let drawable = view.currentDrawable else {
            logger.error(component: "mglRenderer2", details: "Could not get current drawable, aborting render pass.")
            commandInterface.done(command: command, success: false)
            return
        }

        // This call to getRenderPassDescriptor(view: view) internally calls view.currentRenderPassDescriptor.
        // The call to view.currentRenderPassDescriptor impicitly accessed the view's currentDrawable, as mentioned above.
        // It's possible to swap the order of these calls.
        // But whichever one we call first seems to pay the same blocking/synchronization price when memory usage is high.
        guard let renderPassDescriptor = colorRenderingState.getRenderPassDescriptor(view: view) else {
            logger.error(component: "mglRenderer2", details: "Could not get render pass descriptor from current color rendering config, aborting render pass.")
            commandInterface.done(command: command, success: false)
            return
        }
        depthStencilState.configureRenderPassDescriptor(renderPassDescriptor: renderPassDescriptor)

        guard let commandBuffer = mglRenderer.commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            logger.error(component: "mglRenderer2", details: "Could not get command buffer and renderEncoder from the command queue, aborting render pass.")
            commandInterface.done(command: command, success: false)
            return
        }
        depthStencilState.configureRenderEncoder(renderEncoder: renderEncoder)

        // Attach our view transform to the same location expected by all vertex shaders (our convention).
        renderEncoder.setVertexBytes(&deg2metal, length: MemoryLayout<float4x4>.stride, index: 1)

        //
        // 2. Enter a tight loop to accept more commands in the same frame.
        //

        while !(command is mglFlushCommand) {
            // This command is either:
            //  - the command received above with framesRemaining > 0, which initiated this frame's tight loop
            //  - another command received below which is being processed as part of the same frame
            let drawSuccess = command.draw(
                logger: logger,
                view: view,
                depthStencilState: depthStencilState,
                colorRenderingState: colorRenderingState,
                deg2metal: &deg2metal,
                renderEncoder: renderEncoder
            )

            // On failure, end the frame.
            if !drawSuccess {
                commandInterface.done(command: command, success: false)
                renderEncoder.endEncoding()
                colorRenderingState.finishDrawing(commandBuffer: commandBuffer, drawable: drawable)
                return
            }

            // On success, count the command as having drawn a frame.
            command.framesRemaining -= 1

            // We have special case for "repeating" commands which draw across multiple frames.
            if command.framesRemaining > 0 {
                // Re-add this command to process it again on the next frame.
                commandInterface.doAgain(command: command)

                // Automatically flush this command and report its timestamp at the start of the next frame.
                commandInterface.done(command: command, sendNow: false)
                renderEncoder.endEncoding()
                colorRenderingState.finishDrawing(commandBuffer: commandBuffer, drawable: drawable)
                return
            }

            // Normal, non-repeating commands can just be done now.
            commandInterface.done(command: command)

            // Tight loop: wait for the next command here in the same frame.
            if let nextCommand = commandInterface.awaitNext(device: device) {
                command = nextCommand

                // Let the next command get or set app state, even during the frame tight loop.
                let nextNondrawingSuccess = command.doNondrawingWork(
                    logger: logger,
                    view: view,
                    depthStencilState: depthStencilState,
                    colorRenderingState: colorRenderingState,
                    deg2metal: &deg2metal
                )

                // On failure, end the frame.
                if !nextNondrawingSuccess {
                    commandInterface.done(command: command, success: false)
                    renderEncoder.endEncoding()
                    colorRenderingState.finishDrawing(commandBuffer: commandBuffer, drawable: drawable)
                    return
                }

            } else {
                // This is unexpected, maybe the client disconnected or sent bad data.
                // Just end the frame.
                renderEncoder.endEncoding()
                colorRenderingState.finishDrawing(commandBuffer: commandBuffer, drawable: drawable)
                return
            }
        }

        // This command is the flush command that got us out of the frame tight loop.
        // Report its processed time at the start of the next frame.
        command.framesRemaining -= 1
        commandInterface.done(command: command, sendNow: false)

        //
        // 3. Present the frame representing all commands until "flush".
        //

        renderEncoder.endEncoding()
        colorRenderingState.finishDrawing(commandBuffer: commandBuffer, drawable: drawable)
    }
}
