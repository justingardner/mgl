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
 - this fills in success status and timing results around each command
 This reports completed commands back to our mglCommandInterface, but doesn't know what happens from there.
 */
class mglRenderer2: NSObject {
    // A logging interface that handles macOS version dependency and remembers the last error message.
    private let logger: mglLogger

    // GPU Device!
    private let device: MTLDevice

    // GPU and CPU buffers where we can gather and read out detailed redering pipeline timestamps (if GPU supports).
    // We configure render passes to store timestamps in the GPU buffer, then explicitly blit the results to the CPU buffer.
    // There's supposed to be an easier API with one shared GPU buffer, but it seems not to work in general -- even on an M1 iMac!
    // https://developer.apple.com/documentation/metal/gpu_counters_and_counter_sample_buffers/converting_a_gpu_s_counter_data_into_a_readable_format
    private let gpuTimestampBuffer: MTLCounterSampleBuffer?
    private let cpuTimestampBuffer: MTLBuffer?

    // Remember timing around drawable acquisition and presentation (if OS supports)
    private var drawablePresentedTime: Double = 0.0

    // Utility to get system nano time.
    let secs = mglSecs()

    // The Metal commandQueue tells the device what to do.
    private let commandQueue: MTLCommandQueue!

    // Our command interface communicates with the client process like Matlab.
    private let commandInterface: mglCommandInterface

    // This holds a flush command from the previous frame.
    // Its timing results will be filled in at the start of the next frame.
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

        // Try to set up buffers to holder detailed pipeline stage timestamps.
        // The timestamps we want are "stage boundary" timestamps before and after the vertex and fragment pipeline stages.
        // Not all OS versions and GPUs support these timestamps.
        let supportsStageBoundaryTimestamps = gpuSupportsStageBoundaryTimestamps(logger: logger, device: device)

        // We also need to check whether the GPU is capable of repording timestamps to a buffer at all.
        let timestampCounterSet = getGpuTimestampCounter(logger: logger, device: device)

        if supportsStageBoundaryTimestamps && timestampCounterSet != nil {
            // OK we can try to set up buffers for detailed pipeline timestamps.
            gpuTimestampBuffer = makeGpuTimestampBuffer(logger: logger, device: device, counterSet: timestampCounterSet!)
            cpuTimestampBuffer = makeCpuTimestampBuffer(logger: logger, device: device)
            if gpuTimestampBuffer != nil && cpuTimestampBuffer != nil {
                logger.info(component: "mglRenderer2",
                            details: "OK -- Created GPU buffer to collect detailed pipeline stage timestamps.")
            } else {
                logger.info(component: "mglRenderer2",
                            details: "Could not create GPU and CPU timestamp buffers -- frame times will be best-effort.")
            }
        } else {
            // We'll have to fall back on best-effort CPU timestamps.
            gpuTimestampBuffer = nil
            cpuTimestampBuffer = nil
            logger.info(component: "mglRenderer2",
                        details: "GPU device does not support detailed pipeline stage timestmps, frame times will be best-effort.")
        }

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

    // This is called by the system on a frame-by-frame schedule.
    private func render(in view: MTKView) {
        if (lastFlushCommand != nil) {
            // This block will execute on the next frame, after we drew graphics and presented a previous frame.
            // This is a convenient place/time to report what happened on the previous frame.

            // When was the previous frame presented?
            if drawablePresentedTime == 0.0 {
                // On older systems this is when we make a best effort to *measure* the presented time.
                lastFlushCommand!.results.drawablePresented = secs.get()
            } else {
                // On macOS 11.0 and later, we can read out the presented time recorded for us by the system.
                // See the drawable addPresentedHandler(), below.
                lastFlushCommand!.results.drawablePresented = drawablePresentedTime
            }

            // We now consider this flush command complete, and we don't expect this block to run until we draw again.
            commandInterface.done(command: lastFlushCommand!)
            lastFlushCommand = nil
        }

        // Let the command interface read new commands from the client, if any.
        // This will return after reading in zero or more available commands -- it won't block.
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

        // Record how long it took to acquire the drawable in response to this drawing command.
        command.results.drawableAcquired = secs.get()

        // If supported, let the system tell us when the drawable was presented.
        self.drawablePresentedTime = 0.0
        if #available(macOS 10.15.4, *) {
            view.currentDrawable?.addPresentedHandler({ [weak self] drawable in
                // This weak and strong self business is clunky but recommended.
                // https://developer.apple.com/documentation/metal/mtldrawable/2806858-addpresentedhandler
                // It prevents circular referencing between self (this mglRenderer2) and the callback itself (also an object).
                guard let strongSelf = self else {
                    return
                }
                strongSelf.drawablePresentedTime = drawable.presentedTime
            })
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

        // If supported by OS and GPU, set up to store detailed pipeline stage timestamps during the render pass.
        // Later, when we have a flush command in hand, we'll read the timestamps into the flush command results.
        setUpRenderPassGpuTimestamps(renderPassDescriptor: renderPassDescriptor)

        // The command buffer and render encoder are how we instruct the GPU to draw things on each frame.
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
            // Here at the top of the tight loop, this command is either:
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

                // If supported by OS and GPU, resolve pipeline stage timestamps gethered during the render pass.
                resolveRenderPassGpuTimestamps(commandBuffer: commandBuffer, command: command)

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
        // We'll report out timing details from this "lastFlushCommand" at the start of the next frame.
        command.framesRemaining -= 1
        lastFlushCommand = command

        //
        // 3. Present the frame representing all commands until "flush".
        //

        renderEncoder.endEncoding()

        // If supported by OS and GPU, resolve pipeline stage timestamps gethered during the render pass.
        resolveRenderPassGpuTimestamps(commandBuffer: commandBuffer, command: command)

        colorRenderingState.finishDrawing(commandBuffer: commandBuffer, drawable: drawable)
    }

    /*
     Set up the current render pass to record detailed pipeline stage timestamps, if supported by OS and GPU.
     This only seems to be available on macOS 11.0 and later (Big Sur 2020).
     */
    private func setUpRenderPassGpuTimestamps(renderPassDescriptor: MTLRenderPassDescriptor) {
        guard let gpuTimestampBuffer = self.gpuTimestampBuffer else {
            return
        }

        if #available(macOS 11.0, *) {
            guard let sampleAttachment = renderPassDescriptor.sampleBufferAttachments[0] else {
                return
            }
            sampleAttachment.sampleBuffer = gpuTimestampBuffer
            sampleAttachment.startOfVertexSampleIndex = 0
            sampleAttachment.endOfVertexSampleIndex = 1
            sampleAttachment.startOfFragmentSampleIndex = 2
            sampleAttachment.endOfFragmentSampleIndex = 3
        }
    }

    /*
     Resolve detailed pipeline state timestamps from the GPU buffer to the CPU buffer.
     This only seems to be available on macOS 11.0 and later (Big Sur 2020).
     */
    private func resolveRenderPassGpuTimestamps(commandBuffer: MTLCommandBuffer, command: mglCommand) {
        guard let gpuTimestampBuffer = self.gpuTimestampBuffer,
              let cpuTimestampBuffer = self.cpuTimestampBuffer else {
            return
        }

        if #available(macOS 11.0, *) {
            // Explicitly blit recorded timestamps from the GPU's private buffer to the CPU buffer we can read.
            // Doing this explicitly with two buffers and a blit seems to be the more reliable of two documented approaches:
            // https://developer.apple.com/documentation/metal/gpu_counters_and_counter_sample_buffers/converting_a_gpu_s_counter_data_into_a_readable_format
            guard let bltCommandEncoder = commandBuffer.makeBlitCommandEncoder() else {
                return
            }
            bltCommandEncoder.resolveCounters(gpuTimestampBuffer, range: 0..<4, destinationBuffer: cpuTimestampBuffer, destinationOffset: 0)
            bltCommandEncoder.endEncoding()

            // The GPU timestamps will be recorded and blited later, while the render pass is executing.
            // This callback will run afterwards, when we expect the data to be available.
            commandBuffer.addCompletedHandler { [cpuTimestampBuffer, command] commandBuffer in
                // Copy each timestamp sample into the given command's timing results.
                // This uses the sample buffer array indexes we specified above in setUpRenderPassGpuTimestamps().
                let elementSize = MemoryLayout<MTLCounterResultTimestamp>.size

                // sampleAttachment.startOfVertexSampleIndex = 0
                var vertexStart = MTLCounterResultTimestamp(timestamp: 0)
                memcpy(&vertexStart, cpuTimestampBuffer.contents(), elementSize)
                command.results.vertexStart = Double(vertexStart.timestamp)

                // sampleAttachment.endOfVertexSampleIndex = 1
                var vertexEnd = MTLCounterResultTimestamp(timestamp: 0)
                memcpy(&vertexEnd, cpuTimestampBuffer.contents().advanced(by: elementSize), elementSize)
                command.results.vertexEnd = Double(vertexEnd.timestamp)

                // sampleAttachment.startOfFragmentSampleIndex = 2
                var fragmentStart = MTLCounterResultTimestamp(timestamp: 0)
                memcpy(&fragmentStart, cpuTimestampBuffer.contents().advanced(by: 2 * elementSize), elementSize)
                command.results.fragmentStart = Double(fragmentStart.timestamp)

                // sampleAttachment.endOfFragmentSampleIndex = 3
                var fragmentEnd = MTLCounterResultTimestamp(timestamp: 0)
                memcpy(&fragmentEnd, cpuTimestampBuffer.contents().advanced(by: 3 * elementSize), elementSize)
                command.results.fragmentEnd = Double(fragmentEnd.timestamp)
            }
        }
    }
}

/*
 Check whether the GPU device supports timestamp stampling at pipeline stage boundaries.
 I.e., can we gather start and end of vertex and fragment pipeline stages?
 This only seems to be available on macOS 11.0 and later (Big Sur 2020).
 */
private func gpuSupportsStageBoundaryTimestamps(logger: mglLogger, device: MTLDevice) -> Bool {
    if #available(macOS 11.0, *) {
        // Report all the supported boundaries.
        let allBoundaries: [MTLCounterSamplingPoint: String] = [.atStageBoundary: "atStageBoundary",
                                                                .atDrawBoundary: "atDrawBoundary",
                                                                .atBlitBoundary: "atBlitBoundary",
                                                                .atDispatchBoundary: "atDispatchBoundary",
                                                                .atTileDispatchBoundary: "atTileDispatchBoundary"]
        for (boundary, name) in allBoundaries {
            let boundarySupported = device.supportsCounterSampling(boundary)
            if boundarySupported {
                logger.info(component: "mglRenderer2",
                            details: "GPU device \"\(device.name)\" supports sampling at boundary \(name).")
            } else {
                logger.info(component: "mglRenderer2",
                            details: "GPU device \"\(device.name)\" does not support sampling at boundary \(name).")
            }
        }

        // Check the one we're specifically interested in.
        return device.supportsCounterSampling(.atStageBoundary)
    } else {
        logger.info(component: "mglRenderer2",
                    details: "GPU processing stage timestamps are only available on macOS 11.0 or later.")
        return false
    }
}

/*
 Check which counter sets and counters the GPU device supports.
 If the timestamp counter is available, return its counter set so we can use it to gather detailed frame timing.
 */
private func getGpuTimestampCounter(logger: mglLogger, device: MTLDevice) -> MTLCounterSet? {
    guard let counterSets = device.counterSets else {
        logger.info(component: "mglRenderer2",
                    details: "GPU device \"\(device.name)\" doesn't support any counter sets.")
        return nil
    }

    var timestampCounterSet: MTLCounterSet? = nil
    for counterSet in counterSets {
        for counter in counterSet.counters {
            logger.info(component: "mglRenderer2",
                        details: "GPU device \"\(device.name)\" supports counter set \"\(counterSet.name)\" with counter \"\(counter.name)\".")

            if counterSet.name == MTLCommonCounterSet.timestamp.rawValue && counter.name == MTLCommonCounter.timestamp.rawValue {
                timestampCounterSet = counterSet
            }
        }
    }
    return timestampCounterSet
}

/*
 Create a new GPU buffer where we can store detailed pipline stage timestamps.
 The buffer will be "private" for GPU access only.
 The buffer will store 4 timestamps: vertex stage start and end, plus fragment stage start and end.
 */
private func makeGpuTimestampBuffer(logger: mglLogger, device: MTLDevice, counterSet: MTLCounterSet) -> MTLCounterSampleBuffer? {
    let descriptor = MTLCounterSampleBufferDescriptor()
    descriptor.counterSet = counterSet
    descriptor.storageMode = .private
    descriptor.sampleCount = 4
    guard let buffer = try? device.makeCounterSampleBuffer(descriptor: descriptor) else {
        logger.error(component: "mglRenderer2", details: "Device failed to create a GPU counter sample buffer.")
        return nil
    }
    return buffer
}

/*
 Create a new CPU buffer where we can read out detailed pipline stage timestamps.
 The buffer will be "shared" for GPU as well as CPU access.
 The buffer will store 4 timestamps: vertex stage start and end, plus fragment stage start and end.
 */
private func makeCpuTimestampBuffer(logger: mglLogger, device: MTLDevice) -> MTLBuffer? {
    let counterBufferLength = MemoryLayout<MTLCounterResultTimestamp>.size * 4
    guard let buffer = device.makeBuffer(length: counterBufferLength, options: .storageModeShared) else {
        logger.error(component: "mglRenderer2", details: "Device failed to create a CPU counter sample buffer.")
        return nil
    }
    return buffer
}
