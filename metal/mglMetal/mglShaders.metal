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

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Dots
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/

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
// Arcs
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/

struct VertexArcsIn {
    float4 position [[ attribute(0) ]];
    float4 color [[ attribute(1) ]];
    float2 radii [[ attribute(2) ]];
    float2 wedge [[ attribute(3) ]];
    float border_pixels [[ attribute(4) ]];
};

struct VertexArcsOut {
    float4 position [[position]];
    float4 color;
    float point_size [[point_size]];
    float inner;
    float start_angle;
    float half_sweep;
    float half_border;
};

vertex VertexArcsOut vertex_arcs(const VertexArcsIn vertexIn [[ stage_in ]],
                                 constant float4x4 &deg2metal [[buffer(1)]])
{
    float outer = vertexIn.radii[1];
    VertexArcsOut vertex_out {
        .position = deg2metal * vertexIn.position,
        .color = vertexIn.color,
        .point_size = outer,
        .inner = vertexIn.radii[0] / outer / 2.0,
        .start_angle = vertexIn.wedge[0],
        .half_sweep = vertexIn.wedge[1] / 2.0,
        .half_border = vertexIn.border_pixels / outer / 2.0
    };
    return(vertex_out);
}

fragment float4 fragment_arcs(const VertexArcsOut in [[stage_in]],
                              const float2 point_coord [[point_coord]]) {

    // Carve out an annulus.
    float2 centered_coord = point_coord - 0.5;
    float r = length(centered_coord);
    float a_inner = smoothstep(in.inner - in.half_border, in.inner + in.half_border, r);
    float a_outer = 1.0 - smoothstep(0.5 - in.half_border, 0.5 + in.half_border, r);

    // Carve out a wedge.
    float angle = atan2(-centered_coord[1], centered_coord[0]);
    float positive_center = in.start_angle + in.half_sweep;
    float angle_to_positive_center = abs(angle - positive_center);
    float a_positive = 1.0 - smoothstep(in.half_sweep - in.half_border, in.half_sweep + in.half_border, angle_to_positive_center);
    float negative_center = in.start_angle - 2.0 * M_PI_F + in.half_sweep;
    float angle_to_negative_center = abs(angle - negative_center);
    float a_negative = 1.0 - smoothstep(in.half_sweep - in.half_border, in.half_sweep + in.half_border, angle_to_negative_center);
    float a_wedge = a_positive + a_negative;

    float a = in.color[3] * a_inner * a_outer * a_wedge;
    return float4(in.color[0], in.color[1], in.color[2], a);
}

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Textures
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/

struct VertexTextureIn {
    float4 position [[ attribute(0) ]];
    float2 texCoords [[ attribute(1) ]];
};

struct VertexTextureOut {
    float4 position [[position]];
    float2 texCoords;
};

vertex VertexTextureOut vertex_textures(const VertexTextureIn vertexIn [[ stage_in ]],
                                        constant float4x4 &deg2metal [[buffer(1)]]) {
    VertexTextureOut vertex_out {
        .position = deg2metal * vertexIn.position,
        .texCoords = vertexIn.texCoords
    };
    return(vertex_out);
}

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

struct VertexWithColorIn {
    float4 position [[ attribute(0) ]];
    float3 c [[ attribute(1) ]];
};

struct VertexWithColorOut {
    float4 position [[position]];
    float3 c;
};

vertex VertexWithColorOut vertex_with_color(const VertexWithColorIn vertexIn [[ stage_in ]],
                                            constant float4x4 &deg2metal [[buffer(1)]]) {
    VertexWithColorOut vertex_out {
        .position = deg2metal * vertexIn.position,
        .c = vertexIn.c
    };
    return(vertex_out);
}

fragment float4 fragment_with_color(VertexWithColorOut in [[stage_in]]) {
    return(float4(in.c, 1));
}
