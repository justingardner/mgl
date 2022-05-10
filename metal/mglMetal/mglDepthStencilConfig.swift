//
//  mglStencilConfig.swift
//  mglMetal
//
//  This captures "things we need to do to set up and apply stencils".
//  What does that mean?
//  Things like choosing whether we're creating vs applying a stencil,
//  and which stencil plane we're creating or applying,
//  or maybe we're not using a stencil at all.
//
//  The Metal API is confusing regarding the config for stencils and depth tests.
//  In some parts of the API, these are treated as one feature.
//  For example, the MTLView combines thses with one property, depthStencilPixelFormat.
//  We can specify a pixel format like depth32Float_stencil8,
//  as a way to say that we want both depth and stencil behavior.
//
//  On the other hand, MTLRenderPassDescriptor has separate properties for
//  depthAttachment vs stencilAttachment.
//  Some of the config for these we want to be different, like the storeAction.
//  But the actual textures backing these attachments can be the same object.
//
//  Similarly, MTLRenderPipelineDescriptor has separate properties for
//  depthAttachmentPixelFormat vs stencilAttachmentPixelFormat,
//  even though these both might have the same value of depth32Float_stencil8.
//
//  MTLDepthStencilDescriptor deals with both stencils and depth,
//  this is where we specify behaviors like writing to stencil vs using a stencil as a mask.
//
//  So, long way of saying -- the API is confusing and we need to coordinate
//  things across a few different parts of the API.
//  Instead of adding lots of conditionals, each time we touch one of those parts of the API,
//  better to combine cohesive sets of behavior in one place here.
//
//  Created by Benjamin Heasly on 5/5/22.
//  Copyright © 2022 GRU. All rights reserved.
//

import Foundation
import MetalKit

protocol mglDepthStencilConfig {
    func configureRenderPassDescriptor(renderPassDescriptor: MTLRenderPassDescriptor)
    func configureRenderEncoder(renderEncoder: MTLRenderCommandEncoder)
}

class mglEnableDepthAndStencilTest : mglDepthStencilConfig {
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

class mglEnableDepthAndStencilCreate : mglDepthStencilConfig {
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
