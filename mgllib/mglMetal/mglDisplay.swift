//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
//
//  mglDisplay.swift
//  mglStandaloneDisplay
//
//  Created by justin gardner on 12/25/2019.
//  Copyright © 2019 GRU. All rights reserved.
//  Purpose: Class that handles all drawing to the screen
//           using metal API
//
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/

import Foundation
import SwiftUI
import MetalKit

class mglDisplay
{
    var metalView : MTKView!
    var device : MTLDevice!

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // init
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    init () {
        //        guard let device = MTLCreateSystemDefaultDevice() else {
        //    fatalError("(mglStandaloneDisplay) GPU does not have Metal support")
        device = MTLCreateSystemDefaultDevice()
        // set up metal view
        let frame = CGRect(x:0, y:0, width: 480, height:300)
        metalView = MTKView(frame: frame, device: device)
        metalView.clearColor = MTLClearColor(red: 0, green: 1, blue: 0.8, alpha: 1)
    }
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // draw
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func draw () {

        // make a sphere
        let allocator = MTKMeshBufferAllocator(device:device)
        let mdlMesh = MDLMesh(sphereWithExtent: [0.75, 0.75, 0.75],
                              segments: [100,100],
                              inwardNormals: false,
                              geometryType: .triangles,
                              allocator: allocator)
        let mesh = try! MTKMesh(mesh: mdlMesh, device: device)
                
        // create command queue
        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("(mglStandaloneDisplay) Could not create a command queue")
        }
                
        // create shader
        let shader = """
        #include <metal_stdlib>
        using namespace metal;

        struct VertexIn {
          float4 position [[ attribute(0) ]];
        };

        vertex float4 vertex_main(const VertexIn vertex_in [[ stage_in ]]) {
          return vertex_in.position;
        }

        fragment float4 fragment_main() {
          return float4(0.7, 0.3, 0.8, 1);
        }
        """
        // create library with the shader
        let library = try! device.makeLibrary(source: shader, options: nil)
        let vertexFunction = library.makeFunction(name: "vertex_main")
        let fragmentFunction = library.makeFunction(name: "fragment_main")
                
        // Make pipeline descriptor
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mesh.vertexDescriptor)
                
        // create the pipeline state
        let pipelineState = try! device.makeRenderPipelineState(descriptor: descriptor)
                
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
            let renderPassDescriptor = metalView.currentRenderPassDescriptor,
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
            else { fatalError() }
                
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: 0, index: 0)
                
        guard let submesh = mesh.submeshes.first else { fatalError() }
                
        renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: 0)
                
        renderEncoder.endEncoding()
        guard let drawable = metalView.currentDrawable else { fatalError() }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
