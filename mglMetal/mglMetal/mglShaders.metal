//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
//
//  mglShaders.metal
//  mglMetal
//
//  Created by justin gardner on 12/28/2019.
//  Copyright © 2019 GRU. All rights reserved.
//
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Include section
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
#include <metal_stdlib>
using namespace metal;

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Vertex shader stucture
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
struct VertexIn {
  float4 position [[ attribute(0) ]];
};
                                                                                          
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Vertex shader
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
vertex float4 vertex_main(const VertexIn vertexIn [[ stage_in ]]) {
  float4 position = vertexIn.position;
  return position;
}

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Fragment shader
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
fragment float4 fragment_main() {
  return float4(1, 0, 0, 1);
}

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Fragment shader for rendering dots
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
fragment float4 fragment_dots() {
  return float4(0, 1, 0, 1);
}

