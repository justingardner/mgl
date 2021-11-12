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
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Dots
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Vertex shader for rendering dots
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
vertex VertexOut vertex_dots(const device packed_float3* vertex_array [[ buffer(0) ]],
                             constant float4x4 &deg2metal [[buffer(1)]],
                             constant float &pointSize [[buffer(2)]],
                             unsigned int vid [[ vertex_id ]])
{
    VertexOut vertex_out {
        .position = deg2metal * float4(vertex_array[vid], 1),
        .point_size = pointSize
    };
    return(vertex_out);
}

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Fragment shader for rendering dots
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
fragment float4 fragment_dots(const VertexOut in [[stage_in]],
                              const float2 pointCoord [[point_coord]],
                              constant simd_float3 &color [[buffer(0)]],
                              constant uint32_t &isRound [[buffer(1)]]) {
    if (isRound) {
        float pointRadius = length(pointCoord - float2(0.5f));
        float a = 1.0 - smoothstep(0.49, 0.5, pointRadius);
        return float4(color[0], color[1], color[2], a);
    } else {
        return float4(color[0], color[1], color[2], 1);
    }
}

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Textures
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Vertex In Structure for textures
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
struct VertexTextureIn {
  float4 position [[ attribute(0) ]];
  float2 texCoords [[ attribute(1) ]];
};

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Vertex Out Structure for textures
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
struct VertexTextureOut {
    float4 position [[position]];
    float2 texCoords;
};

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Vertex shader for textures
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
vertex VertexTextureOut vertex_textures(const VertexTextureIn vertexIn [[ stage_in ]],
                             constant float4x4 &deg2metal [[buffer(1)]]) {
  VertexTextureOut vertex_out {
      .position = deg2metal * vertexIn.position,
      .texCoords = vertexIn.texCoords
  };
  return(vertex_out);
}

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Fragment shader for rendering textures
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
fragment float4 fragment_textures(VertexTextureOut in [[stage_in]],
                                  texture2d<float> myTexture [[texture(0)]],
                                  sampler mySampler [[sampler(0)]] ,
                                  constant float &phase [[buffer(2)]]) {
//    return(myTexture.sample(mySampler, in.texCoords));
    float4 c = myTexture.sample(mySampler, in.texCoords+phase);
    float4 calpha = myTexture.sample(mySampler, in.texCoords);
    return(float4(c[0], c[1], c[2], calpha[3]));
}

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Vertex with color
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Vertex with color In Structure
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
struct VertexWithColorIn {
  float4 position [[ attribute(0) ]];
  float3 c [[ attribute(1) ]];
};

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Vertex with color Out Structure
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
struct VertexWithColorOut {
    float4 position [[position]];
    float3 c;
};

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Vertex with color shader
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
vertex VertexWithColorOut vertex_with_color(const VertexWithColorIn vertexIn [[ stage_in ]],
                             constant float4x4 &deg2metal [[buffer(1)]]) {
  VertexWithColorOut vertex_out {
      .position = deg2metal * vertexIn.position,
      .c = vertexIn.c
  };
  return(vertex_out);
}
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Fragment shader with colors
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
fragment float4 fragment_with_color(VertexWithColorOut in [[stage_in]]) {
    return(float4(in.c, 1));
}

