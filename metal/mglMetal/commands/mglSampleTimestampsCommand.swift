//
//  mglSampleTimestamps.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/30/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation
import MetalKit

class mglSampleTimestampsCommand : mglCommand {
    private let device: MTLDevice
    private var cpu: Double = 0.0
    private var gpu: Double = 0.0

    init(device: MTLDevice) {
        // Hold on to the device so we can use it later, when the command is executed.
        self.device = device
    }

    override func doNondrawingWork(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        deg2metal: inout simd_float4x4,
        targetPresentationTimestamp: CFTimeInterval?
    ) -> Bool {
        if #available(macOS 11.0, *) {
            // Sample CPU and GPU timestamps "from the same moment in time", according to sampleTimestamps() docs.
            let (cpuSample, gpuSample) = device.sampleTimestamps()

            // Convert the CPU timestamp to seconds.
            // According to docs, the CPU timestamp is "nanoseconds for a point in absolute time or Mach absolute time",
            // Which I think makes it comparable to what we have in mglGetSecs (in Matlab) and mglSecs (in this app).
            // - https://developer.apple.com/documentation/metal/gpu_counters_and_counter_sample_buffers/converting_gpu_timestamps_into_cpu_time#3730882
            // - https://developer.apple.com/documentation/metal/mtltimestamp?changes=_3
            cpu = Double(cpuSample) * 1e-9

            // Leave the gpu timestamp as-is (assuming it fits in a double).
            gpu = Double(gpuSample)
        }
        return true
    }

    override func writeQueryResults(
        logger: mglLogger,
        commandInterface : mglCommandInterface
    ) -> Bool {
        _ = commandInterface.writeDouble(data: cpu)
        _ = commandInterface.writeDouble(data: gpu)
        return true
    }
}
