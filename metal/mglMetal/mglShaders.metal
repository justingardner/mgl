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
struct VertexDotsIn {
    float4 position [[ attribute(0) ]];
    float4 color [[ attribute(1) ]];
    float2 size [[ attribute(2) ]];
    float is_round [[ attribute(3) ]];
    float border_pixels [[ attribute(4) ]];
};

struct VertexDotsOut {
    float4 position [[position]];
    float4 color;
    float2 half_size;
    float point_size [[point_size]];
    bool is_round;
    float half_border;
};

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Dots
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Vertex shader for rendering dots
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
vertex VertexDotsOut vertex_dots(const VertexDotsIn vertexIn [[ stage_in ]],
                                 constant float4x4 &deg2metal [[buffer(1)]])
{
    float point_size = max(vertexIn.size[0], vertexIn.size[1]);
    VertexDotsOut vertex_out {
        .position = deg2metal * vertexIn.position,
        .color = vertexIn.color,
        .half_size = vertexIn.size / point_size / 2.0,
        .point_size = point_size,
        .is_round = bool(vertexIn.is_round),
        .half_border = vertexIn.border_pixels / point_size / 2.0
    };
    return(vertex_out);
}

// basic square
//    float a = 1.0;

// rounded circle
//    float pointRadius = length(pointCoord - float2(0.5f));
//    float a = 1.0 - smoothstep(0.49, 0.5, pointRadius);

// basic rectangle
//    float half_width = 0.4;
//    float half_height = 0.2;
//    float a_x = 1.0 - smoothstep(half_width, half_width, abs(pointCoord[0] - 0.5));
//    float a_y = 1.0 - smoothstep(half_height, half_height, abs(pointCoord[1] - 0.5));
//    float a = a_x * a_y;

// rounded annulus
//    float inner_radius = 0.3;
//    float pointRadius = length(pointCoord - float2(0.5f));
//    float a_inner = smoothstep(inner_radius, inner_radius + 0.01, pointRadius);
//    float a_outer = 1.0 - smoothstep(0.49, 0.5, pointRadius);
//    float a = a_inner * a_outer;

// rounded ellipse
//    float half_width = 0.5;
//    float half_height = 0.5;
//    float2 pointCoordCentered = pointCoord - float2(0.5f);
//    float ellipseDistance = (pointCoordCentered[0]*pointCoordCentered[0]) / (half_width*half_width) + (pointCoordCentered[1]*pointCoordCentered[1]) / (half_height*half_height);
//    float a = 1.0 - smoothstep(0.99, 1.0, ellipseDistance);

// partial disk
// start_angle and sweep_angle in [0, 2pi]
//    float start_angle = M_PI_F / 6.0 + 3.0 * M_PI_F / 2.0;
//    float half_sweep = M_PI_F / 4.0;
//    float2 pointCoordCentered = pointCoord - float2(0.5f);
//    float point_angle = atan2(-pointCoordCentered[1], pointCoordCentered[0]);
//    float point_deviation_positive = abs(point_angle - start_angle - half_sweep);
//    float a_positive = 1.0 - smoothstep(half_sweep-0.01, half_sweep + 0.01, point_deviation_positive);
//    float point_deviation_negative = abs(point_angle - (start_angle - 2.0 * M_PI_F) - half_sweep);
//    float a_negative = 1.0 - smoothstep(half_sweep-0.01, half_sweep + 0.01, point_deviation_negative);
//    float a = a_positive + a_negative;
//
//    return float4(color[0], color[1], color[2], a);


//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Fragment shader for rendering dots
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
fragment float4 fragment_dots(const VertexDotsOut in [[stage_in]],
                              const float2 point_coord [[point_coord]]) {

    float2 centered_coord = abs(point_coord - 0.5);
    if (in.is_round) {
        // Make a rounded ellipse within the point.
        float radius = (centered_coord[0] * centered_coord[0]) / (in.half_size[0] * in.half_size[0])
                     + (centered_coord[1] * centered_coord[1]) / (in.half_size[1] * in.half_size[1]);
        float a_r = 1.0 - smoothstep(1.0 - in.half_border, 1.0 + in.half_border, radius);
        float a = in.color[3] * a_r;
        return float4(in.color[0], in.color[1], in.color[2], a);
    } else {
        // Make a rectangle within the point.
        float a_x = 1.0 - smoothstep(in.half_size[0], in.half_size[0], centered_coord[0]);
        float a_y = 1.0 - smoothstep(in.half_size[1], in.half_size[1], centered_coord[1]);
        float a = in.color[3] * a_x * a_y;
        return float4(in.color[0], in.color[1], in.color[2], a);
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

