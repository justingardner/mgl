//
//  mglArcsConmmand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/4/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation
import MetalKit

class mglArcsCommand : mglCommand {
    private let centerVertex: MTLBuffer
    private let arcCount: Int

    init(centerVertex: MTLBuffer, arcCount: Int) {
        self.centerVertex = centerVertex
        self.arcCount = arcCount
        super.init(framesRemaining: 1)
    }

    init?(commandInterface: mglCommandInterface, device: MTLDevice) {
        // read the center vertex for the arc from the commandInterface
        // extra values are rgba (1x4), radii (1x4), wedge (1x2), border (1x1)
        guard let (centerVertex, arcCount) = commandInterface.readVertices(device: mglRenderer.device, extraVals: 11) else {
            return nil
        }
        self.centerVertex = centerVertex
        self.arcCount = arcCount
        super.init(framesRemaining: 1)
    }

    override func draw(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        deg2metal: inout simd_float4x4,
        renderEncoder: MTLRenderCommandEncoder
    ) -> Bool {
        // get an MTLBuffer from the GPU for storing the vertices for two triangles (i.e.
        // we are going to make a square around where the arc is going to be drawn, and
        // then color the pixels in the fragment shader according to how far they are away
        // from the center.) Note that the vertices will have 3 + 2 more values than the
        // centerVertex passed in, because each of these vertices will get the xyz of the
        // centerVertex added on (which is used for the calculation for how far away each
        // pixel is from the center in the fragment shader) and the viewport dimensions
        let byteCount = 6 * ((centerVertex.length/arcCount) + 5 * MemoryLayout<Float>.stride);
        guard let triangleVertices = view.device?.makeBuffer(length: byteCount * arcCount, options: .storageModeManaged) else {
            logger.error(component: "mglArcsCommand", details: "Could not make vertex buffer of size \(byteCount)")
            return false
        }

        // get size of buffer as number of floats, note that we add
        // 3 floats for the center position plus 2 floats for the viewport dimensions
        let vertexBufferSize = 5 + (centerVertex.length/arcCount)/MemoryLayout<Float>.stride;

        // get pointers to the buffer that we will pass to the renderer
        let triangleVerticesPointer = triangleVertices.contents().assumingMemoryBound(to: Float.self);

        // get the viewport size, which may be the on-screen view or an offscreen texture
        let (viewportWidth, viewportHeight) = colorRenderingState.getSize(view: view)

        // iterate over how many vertices (i.e. how many arcs) that the user passed in
        for iArc in 0..<arcCount {
            let centerVertexPointer = centerVertex.contents().assumingMemoryBound(to: Float.self) + iArc * (centerVertex.length/arcCount)/MemoryLayout<Float>.stride
            // Now create the vertices of each corner of the triangles by copying
            // the centerVertex in and then modifying the x, y location appropriately
            // get desired x and y locations of the triangle corners
            let x = centerVertexPointer[0];
            let y = centerVertexPointer[1];
            // radius is the outer radius + half the border
            let rX = centerVertexPointer[8]+centerVertexPointer[13]/2;
            let rY = centerVertexPointer[10]+centerVertexPointer[13]/2;
            let xLocs: [Float] = [x-rX, x-rX, x+rX, x-rX, x+rX, x+rX]
            let yLocs: [Float] = [y-rY, y+rY, y+rY, y-rY, y-rY, y+rY]

            // iterate over 6 vertices (which will be the corners of the triangles)
            for iVertex in 0...5 {
                // get a pointer to the location in the triangleVertices where we want to copy into
                let thisTriangleVerticesPointer = triangleVerticesPointer + iVertex*vertexBufferSize + iArc*vertexBufferSize*6;
                // and copy the center vertex into each location
                memcpy(thisTriangleVerticesPointer, centerVertexPointer, centerVertex.length/arcCount);
                // now set the xy location
                thisTriangleVerticesPointer[0] = xLocs[iVertex];
                thisTriangleVerticesPointer[1] = yLocs[iVertex];
                // and set the centerVertex
                thisTriangleVerticesPointer[14] = centerVertexPointer[0]
                thisTriangleVerticesPointer[15] = -centerVertexPointer[1]
                thisTriangleVerticesPointer[16] = centerVertexPointer[2]
                // and set viewport dimension
                thisTriangleVerticesPointer[17] = viewportWidth
                thisTriangleVerticesPointer[18] = viewportHeight
            }

        }

        // Draw all the arcs
        renderEncoder.setRenderPipelineState(colorRenderingState.getArcsPipelineState())
        renderEncoder.setVertexBuffer(triangleVertices, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6*arcCount)
        return true
    }
}
