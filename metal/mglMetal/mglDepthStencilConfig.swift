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
    var stencilClearValue: UInt32 { get }
    var stencilRefValue: UInt32 { get }
    var stencilLoadAction: MTLLoadAction { get }
    var stencilStoreAction: MTLStoreAction { get }
    func depthStencilDescriptor() -> MTLDepthStencilDescriptor
}

class mglDisableStencils : mglDepthStencilConfig {
    let stencilClearValue: UInt32 = 0
    let stencilRefValue: UInt32 = 0
    let stencilLoadAction: MTLLoadAction = .dontCare
    let stencilStoreAction: MTLStoreAction = .dontCare

    func depthStencilDescriptor() -> MTLDepthStencilDescriptor {
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .lessEqual
        depthStencilDescriptor.isDepthWriteEnabled = true

        // backFaceStencil and frontFaceStencil should defailt to nil -- ie no stencil business.

        return depthStencilDescriptor
    }
}

class mglEnableStencilCreate : mglDepthStencilConfig {
    let stencilMask: UInt32
    let stencilClearValue: UInt32
    let stencilRefValue: UInt32
    let stencilLoadAction: MTLLoadAction = .clear
    let stencilStoreAction: MTLStoreAction = .store

    init(stencilNumber: UInt32, isInverted: Bool) {
        stencilMask = UInt32(1) << (stencilNumber-1)
        stencilClearValue = isInverted ? stencilMask : 0
        stencilRefValue = isInverted ? 0 : stencilMask
    }

    func depthStencilDescriptor() -> MTLDepthStencilDescriptor {
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .lessEqual
        depthStencilDescriptor.isDepthWriteEnabled = true

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

        return depthStencilDescriptor
    }
}

class mglEnableStencilSelect : mglDepthStencilConfig {
    let stencilMask: UInt32
    let stencilClearValue: UInt32 = 0
    let stencilRefValue: UInt32 = 0xFFFFFFFF
    let stencilLoadAction: MTLLoadAction = .load
    let stencilStoreAction: MTLStoreAction = .dontCare

    init(stencilNumber: UInt32) {
        stencilMask = UInt32(1) << (stencilNumber-1)
    }

    func depthStencilDescriptor() -> MTLDepthStencilDescriptor {
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .lessEqual
        depthStencilDescriptor.isDepthWriteEnabled = true

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

        return depthStencilDescriptor
    }
}
