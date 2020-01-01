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

struct VertexTextureIn {
  float4 position [[ attribute(0) ]];
  float2 texCoords [[ attribute(1) ]];
};

struct VertexTextureOut {
    float4 position [[position]];
    float2 texCoords;
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

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Vertex shader for textures
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
vertex VertexTextureOut vertex_textures(const VertexTextureIn vertexIn [[ stage_in ]]) {

  VertexTextureOut vertex_out {
      .position = vertexIn.position,
      .texCoords = vertexIn.texCoords
  };
  return(vertex_out);
//  float4 position = vertexIn.position;
//  return position;
}

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Fragment shader for rendering textures
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
fragment float4 fragment_textures(VertexTextureOut in [[stage_in]],
                                  texture2d<float, access::sample> myTexture [[texture(0)]],
                                  sampler samplr [[sampler(0)]]) {
    constexpr sampler s(coord::normalized,address::repeat,filter::linear);
    float4 c = myTexture.sample(s, in.texCoords);
 //   float4 c = myTexture.sample(s, float2(0.5,0.5));
  //  return(c);
    //return float4(texturedColor,1);
    return float4(0.5,c.g,c.b,1);
}

