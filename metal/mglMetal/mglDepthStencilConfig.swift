//
//  mglStencilConfig.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 5/5/22.
//  Copyright © 2022 GRU. All rights reserved.
//

import Foundation
import MetalKit
import os.log

/*
 mglDepthStencilState keeps track the current depth and stencil state for the app, including:
 - whether we're creating or applying a stencil
 - which of 8 stencil planes we're creating or applying, if any

 The Metal API combines depth config and stencil config into one slightly confusing concept.
 So, this is also where we enable depth testing.

 Depth and stencil config needs to be applied at a couple of points for each render pass.
 At each point we need to be consistent about what state we're in and which plane we're using.
 mglDepthStencilState encloses the state-dependent consistency with a polymorphic/strategy approach,
 which seems nicer than having lots of conditionals in the render pass setup code.
 mglRenderer just needs to call configureRenderPassDescriptor() and configureRenderEncoder() at the right time.
 */
class mglDepthStencilState {
    // For each stencil plane, a config we want to apply that stencil.
    private var applyStencilConfig = [mglDepthStencilConfig]()

    // For each stencil plane, configs to use when we are creating that stencil.
    private var createStencilConfig = [mglDepthStencilConfig]()
    private var createInvertedStencilConfig = [mglDepthStencilConfig]()

    // The current config, one of the above.
    private var currentDepthStencilConfig: mglDepthStencilConfig!

    init(device: MTLDevice) {
        // Set up to support 8 stencil planes.
        for index in 0 ..< 8 {
            let number = UInt32(index)

            // Config to apply the stencil for this plane.
            applyStencilConfig.append(mglEnableDepthAndStencilTest(stencilNumber: number, device: device))

            // Configs to create the stencil for this plane.
            createStencilConfig.append(mglEnableDepthAndStencilCreate(stencilNumber: number, isInverted: false, device: device))
            createInvertedStencilConfig.append(mglEnableDepthAndStencilCreate(stencilNumber: number, isInverted: true, device: device))
        }

        // By default, enable the 0th stencil plane (ie no stencil) along with depth testing.
        currentDepthStencilConfig = applyStencilConfig[0]
    }

    // Collaborate with mglRenderer to set up a render pass.
    func configureRenderPassDescriptor(renderPassDescriptor: MTLRenderPassDescriptor) {
        currentDepthStencilConfig.configureRenderPassDescriptor(renderPassDescriptor: renderPassDescriptor)
    }

    // Collaborate with mglRenderer to set up a render pass.
    func configureRenderEncoder(renderEncoder: MTLRenderCommandEncoder) {
        currentDepthStencilConfig.configureRenderEncoder(renderEncoder: renderEncoder)
    }

    // Collaborate with mglRenderer to start creating the stencil plane at the given number.
    func startStencilCreation(view: MTKView, stencilNumber: UInt32, isInverted: Bool) -> Bool {
        let stencilIndex = Array<mglDepthStencilConfig>.Index(stencilNumber)
        if (!createStencilConfig.indices.contains(stencilIndex)) {
            os_log("(mglDepthStencilState) Got stencil number to create %{public}d but only numbers 0-7 are supported.",
                   log: .default, type: .error, stencilNumber)
            return false
        }

        os_log("(mglDepthStencilState) Creating stencil number %{public}d, with isInverted %{public}d.",
               log: .default, type: .info, stencilNumber, isInverted)
        currentDepthStencilConfig = isInverted ? createInvertedStencilConfig[stencilIndex] : createStencilConfig[stencilIndex]
        return true
    }

    // Collaborate with mglRenderer to finish creating the stencil plane at the given number.
    func finishStencilCreation(view: MTKView) -> Bool {
        os_log("(mglDepthStencilState) Finishing stencil creation.",
               log: .default, type: .info)
        currentDepthStencilConfig = applyStencilConfig[0]
        return true
    }

    // Collaborate with mglRenderer to apply the stencil plane at the given number.
    func selectStencil(view: MTKView, renderEncoder: MTLRenderCommandEncoder, stencilNumber: UInt32) -> Bool {
        let stencilIndex = Array<mglDepthStencilConfig>.Index(stencilNumber)
        if (!applyStencilConfig.indices.contains(stencilIndex)) {
            os_log("(mglDepthStencilState) Got stencil number to select %{public}d but only numbers 0-7 are supported.",
                   log: .default, type: .error, stencilNumber)
            return false
        }

        os_log("(mglDepthStencilState) Selecting stencil number %{public}d.",
               log: .default, type: .info, stencilNumber)
        currentDepthStencilConfig = applyStencilConfig[stencilIndex]
        currentDepthStencilConfig.configureRenderEncoder(renderEncoder: renderEncoder)
        return true
    }
}

// Abstract the depth and stencil operations needed for setting up a render pass.
private protocol mglDepthStencilConfig {
    func configureRenderPassDescriptor(renderPassDescriptor: MTLRenderPassDescriptor)
    func configureRenderEncoder(renderEncoder: MTLRenderCommandEncoder)
}

// Implement details for how we apply a stencil plane and depth test.
private class mglEnableDepthAndStencilTest : mglDepthStencilConfig {
    let stencilMask: UInt32
    let depthStencilState: MTLDepthStencilState?

    init(stencilNumber: UInt32, device: MTLDevice) {
        stencilMask = stencilNumber == 0 ? 0 : UInt32(1) << (stencilNumber-1)

        // Filter fragments based on z-value of previously drawn fragments, break ties by last write wins.
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .lessEqual
        depthStencilDescriptor.isDepthWriteEnabled = true

        // Filter fragments based on values previously stored in the stencil buffer.
        depthStencilDescriptor.backFaceStencil.readMask = stencilMask
        depthStencilDescriptor.backFaceStencil.writeMask = stencilMask
        depthStencilDescriptor.backFaceStencil.stencilCompareFunction = .equal
        depthStencilDescriptor.backFaceStencil.stencilFailureOperation = .keep
        depthStencilDescriptor.backFaceStencil.depthFailureOperation = .keep
        depthStencilDescriptor.backFaceStencil.depthStencilPassOperation = .keep

        depthStencilDescriptor.frontFaceStencil.readMask = stencilMask
        depthStencilDescriptor.frontFaceStencil.writeMask = stencilMask
        depthStencilDescriptor.frontFaceStencil.stencilCompareFunction = .equal
        depthStencilDescriptor.frontFaceStencil.stencilFailureOperation = .keep
        depthStencilDescriptor.frontFaceStencil.depthFailureOperation = .keep
        depthStencilDescriptor.frontFaceStencil.depthStencilPassOperation = .keep

        depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)
    }

    func configureRenderPassDescriptor(renderPassDescriptor: MTLRenderPassDescriptor) {
        // Start with the same stencil buffer each frame, as stored previously via mglEnableDepthAndStencilCreate
        renderPassDescriptor.stencilAttachment.loadAction = .load
        renderPassDescriptor.stencilAttachment.storeAction = .dontCare
    }

    func configureRenderEncoder(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setStencilReferenceValue(0xFFFFFFFF)
    }
}

// Implement details for how we create a stencil plane and depth test.
private class mglEnableDepthAndStencilCreate : mglDepthStencilConfig {
    let stencilMask: UInt32
    let stencilRefValue: UInt32
    let depthStencilState: MTLDepthStencilState?

    init(stencilNumber: UInt32, isInverted: Bool, device: MTLDevice) {
        stencilMask = stencilNumber == 0 ? 0 : UInt32(1) << (stencilNumber-1)
        stencilRefValue = isInverted ? 0 : stencilMask

        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .lessEqual
        depthStencilDescriptor.isDepthWriteEnabled = true

        // For all rendered fragments, set stencilRefValue into the stencil buffer.
        depthStencilDescriptor.backFaceStencil.readMask = stencilMask
        depthStencilDescriptor.backFaceStencil.writeMask = stencilMask
        depthStencilDescriptor.backFaceStencil.stencilCompareFunction = .always
        depthStencilDescriptor.backFaceStencil.stencilFailureOperation = .replace
        depthStencilDescriptor.backFaceStencil.depthFailureOperation = .replace
        depthStencilDescriptor.backFaceStencil.depthStencilPassOperation = .replace

        depthStencilDescriptor.frontFaceStencil.readMask = stencilMask
        depthStencilDescriptor.frontFaceStencil.writeMask = stencilMask
        depthStencilDescriptor.frontFaceStencil.stencilCompareFunction = .always
        depthStencilDescriptor.frontFaceStencil.stencilFailureOperation = .replace
        depthStencilDescriptor.frontFaceStencil.depthFailureOperation = .replace
        depthStencilDescriptor.frontFaceStencil.depthStencilPassOperation = .replace

        depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)
    }

    func configureRenderPassDescriptor(renderPassDescriptor: MTLRenderPassDescriptor) {
        if (stencilMask == 0) {
            // An awkward special case to init the whole stencil buffer, clearing its contents to zero.
            // This could have been placed somewhere else, maybe a separate implementation of mglDepthStencilConfig?
            // But we can't really "create" stencil number here, 0 anyway, since 0 means "no stencil".
            // So I'm hijacking this case to interpret "create 0" as "init".
            // We'd want to call this once at startup to init all the stencil planes.
            renderPassDescriptor.stencilAttachment.clearStencil = 0
            renderPassDescriptor.stencilAttachment.loadAction = .clear
        } else {
            // Start with any previously built-up stencil buffer, and save new results for later.
            renderPassDescriptor.stencilAttachment.loadAction = .load
        }
        renderPassDescriptor.stencilAttachment.storeAction = .store
    }

    func configureRenderEncoder(renderEncoder: MTLRenderCommandEncoder) {
        // For all rendered fragments, set the same reference value into the stencil buffer.
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setStencilReferenceValue(stencilRefValue)
    }
}
