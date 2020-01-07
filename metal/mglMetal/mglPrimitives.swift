//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
//
//  mglPrimitives.swift
//  mglMetal
//
//  Created by justin gardner on 12/28/2019.
//  Copyright © 2019 GRU. All rights reserved.
//
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Include section
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
import Foundation
import MetalKit

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Class for creating primitives like cubes and spheres
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
class mglPrimitive {
  //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
  // Cube function
  //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
  class func cube(device: MTLDevice, size: Float) -> MDLMesh {
    let allocator = MTKMeshBufferAllocator(device: device)
    let mesh = MDLMesh(boxWithExtent: [size, size, size],
                       segments: [1, 1, 1],
                       inwardNormals: false, geometryType: .triangles,
                       allocator: allocator)
    return mesh
  }
}
                                                                                          
