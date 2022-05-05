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
    func stencilClearValue() -> UInt32
    func stencilReferenceValue() -> UInt32
    func depthStencilDescriptor() -> MTLDepthStencilDescriptor
}

class mglNoStencil : mglDepthStencilConfig {
    func stencilClearValue() -> UInt32 {
        return 0
    }

    func stencilReferenceValue() -> UInt32 {
        return 0
    }

    func depthStencilDescriptor() -> MTLDepthStencilDescriptor {
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .lessEqual
        depthStencilDescriptor.isDepthWriteEnabled = true
        return depthStencilDescriptor
    }
}
