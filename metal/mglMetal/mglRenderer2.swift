//
//  mglRenderer2.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 12/22/23.
//  Copyright © 2023 GRU. All rights reserved.
//

import Foundation
import MetalKit

/*
 This mglRenderer2 processes commands and handles details of setting up Metal rendering passes for each frame.
 This takes unprocessed commands from our mglCommandInterface, but doesn't know about how the commands were created.
 This processes each command in a few steps, but doesn't worry about the details of each command:
  - doNondrawingWork() is a chance for each command to modify the state of this app and/or gather data about the system.
  - draw() is a chance for each command to draw itself as part of a rendering pass / frame.
  - filling in success status and timing data around each command
 This reports completed commands back to our mglCommandInterface, but doesn't know what happens from there.
 */
class mglRenderer2: NSObject {
    // A logging interface that handles macOS version dependency and remembers the last error message.
    private let logger: mglLogger

    // GPU Device!
    private let device: MTLDevice

    // The Metal commandQueue tells the device what to do.
    private let commandQueue: MTLCommandQueue!

    // Our command interface communicates with the client process like Matlab.
    private let commandInterface : mglCommandInterface

    // This holds a flush command from the previous frame.
    // It's "processed time" will be filled in at the start of the next frame.
    // TODO: lastFlushCommand may change when we incorporate the counters API.
    private var lastFlushCommand: mglCommand? = nil

    // Keep track of depth and stencil state, like creating vs applying a stencil, and which stencil.
    private let depthStencilState: mglDepthStencilState

    // Keep track of color rendering state, like oncreen vs offscreen texture, and which texture.
    private let colorRenderingState: mglColorRenderingState

    // Keeps the current coordinate xform specified by the client, like screen pixels vs device visual degrees.
    private var deg2metal = matrix_identity_float4x4

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
        commandQueue = device.makeCommandQueue()!

        // Inititialize 8 stencil planes and depth testing.
        metalView.depthStencilPixelFormat = .depth32Float_stencil8
        metalView.clearDepth = 1.0
        depthStencilState = mglDepthStencilState(logger: logger, device: device)

        // Initialize color rendering, default to onscreen.
        // Default gray clear color applies to onscreen presentation and offscreen rendering to texture.
        metalView.clearColor = MTLClearColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        colorRenderingState = mglColorRenderingState(logger: logger, device: device, view: metalView)

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
        // TODO: lastFlushCommand may change when we incorporate the counters API.
        if (lastFlushCommand != nil) {
            commandInterface.done(command: lastFlushCommand!)
            lastFlushCommand = nil
        }

        // Let the command interface read a new command from the client, if any.
        // This will return after reading in zero or one commands -- it won't block.
        commandInterface.readAny(device: device)

        // Get the next command to be processed from the command interface, if any.
        // If we don't get one this time, that's fine, we'll check again on the next frame.
        guard var command = commandInterface.next() else {
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

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
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
                // Mark this command as done at the start of the next frame.
                lastFlushCommand = command

                // And also re-add this command so it will be the one processed on the next frame.
                commandInterface.addNext(command: command)

                renderEncoder.endEncoding()
                colorRenderingState.finishDrawing(commandBuffer: commandBuffer, drawable: drawable)
                return
            }

            // Normal, non-repeating commands can just be done now.
            commandInterface.done(command: command)

            // Tight loop: wait for the next command here in the same frame.
            // At this point we assume the client has sent another command, or intends to soon.
            // We don't want to exit the frame early on a race condition, so we are willing to block and wait.
            commandInterface.awaitNext(device: device)
            if let nextCommand = commandInterface.next() {
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
        // Mark it as done at the start of the next frame.
        command.framesRemaining -= 1
        lastFlushCommand = command

        //
        // 3. Present the frame representing all commands until "flush".
        //

        renderEncoder.endEncoding()
        colorRenderingState.finishDrawing(commandBuffer: commandBuffer, drawable: drawable)
    }
}
