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

struct VertexOut {
    float4 position [[position]];
    float point_size [[point_size]];
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
// Vertex shader for dots
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
//vertex VertexOut vertex_dots2(constant float3 *vertices [[buffer(0)]],uint id [[vertex_id]])
vertex VertexOut vertex_dots(const device packed_float3* vertex_array [[ buffer(0) ]], unsigned int vid [[ vertex_id ]])
{
    VertexOut vertex_out {
        .position = float4(vertex_array[vid], 1),
        .point_size = 4.0
    };
    return(vertex_out);
}

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Fragment shader for rendering dots
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
fragment float4 fragment_dots() {
  return float4(1, 1, 1, 1);
}

