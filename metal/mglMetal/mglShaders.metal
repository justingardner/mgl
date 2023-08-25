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
        if (a == 0) {
            // Discard invisible fragment so it won't show up in stencil operations.
            discard_fragment();
        }
        return float4(in.color[0], in.color[1], in.color[2], a);
    } else {
        // Make a rectangle within the point.
        float a_x = 1.0 - smoothstep(in.half_size[0], in.half_size[0], centered_coord[0]);
        float a_y = 1.0 - smoothstep(in.half_size[1], in.half_size[1], centered_coord[1]);
        float a = in.color[3] * a_x * a_y;
        if (a == 0) {
            // Discard invisible fragment so it won't show up in stencil operations.
            discard_fragment();
        }
        return float4(in.color[0], in.color[1], in.color[2], a);
    }
}

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Arcs
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/

struct VertexArcsIn {
    float3 position [[ attribute(0) ]];
    float4 color [[ attribute(1) ]];
    float2 radii [[ attribute(2) ]];
    float2 wedge [[ attribute(3) ]];
    float border_pixels [[ attribute(4) ]];
    float3 centerPosition [[ attribute(5) ]];
    float2 viewportSize [[attribute(6)]];
};

struct VertexArcsOut {
    float4 position [[position]];
    float4 color;
    float point_size [[point_size]];
    float inner;
    float start_angle;
    float half_sweep;
    float half_border;
    float4 centerPosition;
    float2 outerRadius;
    float2 innerRadius;
};

vertex VertexArcsOut vertex_arcs(const VertexArcsIn vertexIn [[ stage_in ]],
                                 constant float4x4 &deg2metal [[buffer(1)]])
{
    float outer = vertexIn.radii[1];
    VertexArcsOut vertex_out {
        .position = deg2metal * float4(vertexIn.position, 1.0),
        .color = vertexIn.color,
        .point_size = 0,//outer,
        .inner = vertexIn.radii[0] / outer / 2.0,
        .start_angle = vertexIn.wedge[0],
        .half_sweep = vertexIn.wedge[1] / 2.0,
        .half_border = vertexIn.border_pixels / outer / 2.0,
        .centerPosition = deg2metal * float4(vertexIn.centerPosition, 1.0),
        .outerRadius = float2((deg2metal[0][0] * vertexIn.radii[1] / 2.0) * vertexIn.viewportSize[0],(deg2metal[1][1] * vertexIn.radii[1] / 2.0) * vertexIn.viewportSize[1]),
        .innerRadius = float2((deg2metal[0][0] * vertexIn.radii[0] / 2.0) * vertexIn.viewportSize[0],(deg2metal[1][1] * vertexIn.radii[0] / 2.0) * vertexIn.viewportSize[1]),
    };
    // convert the centerPosition into pixels
    // divide by homogenous component - probably not necessary, but doesn't hurt
    vertex_out.centerPosition /= vertex_out.centerPosition.w;
    // convert to pixels
    vertex_out.centerPosition.xy = (vertex_out.centerPosition.xy * 0.5 + 0.5) * vertexIn.viewportSize;
    // return the vertex
    return(vertex_out);
}

fragment float4 fragment_arcs(const VertexArcsOut in [[stage_in]]) {
    
    // get the pixel centered on the center of the arc
    float2 centeredPoint = in.position.xy-in.centerPosition.xy;
    
    // compute the polar angle of the point
    float angle = atan2(-centeredPoint[1], centeredPoint[0]);

    // compute the distance from the center position of this pixel
    float distanceToCenter = length(centeredPoint);

    // compute normalized radius. It's normalized differently in X and Y because the pixels may not be square
    // This value should be 1 at the outside radius and 0 at the center
    float outerRadius = sqrt(pow(abs(cos(angle) * distanceToCenter) / in.outerRadius[0],2.0) + pow(abs(sin(angle) * distanceToCenter) / in.outerRadius[1],2.0));
    float innerRadius = sqrt(pow(abs(cos(angle) * distanceToCenter) / in.innerRadius[0],2.0) + pow(abs(sin(angle) * distanceToCenter) / in.innerRadius[1],2.0));

    // get the alpha value for the outer. This will be 1 up until the outer border
    // plus will smoothly ramp (using the builtin smoothstep function) from 1 to 0 alpha
    // over the border piexles
    float a_outer = 1.0 - smoothstep(1.0 - in.half_border, 1.0 + in.half_border, outerRadius);
    float a_inner = smoothstep(1.0 - in.half_border, 1.0 + in.half_border, innerRadius);

    // Now compute the alpha based on how much of a wedge angle is asked for
    float positive_center = in.start_angle + in.half_sweep;
    float angle_to_positive_center = abs(angle - positive_center);
    float a_positive = 1.0 - smoothstep(in.half_sweep - in.half_border, in.half_sweep + in.half_border, angle_to_positive_center);
    float negative_center = in.start_angle - 2.0 * M_PI_F + in.half_sweep;
    float angle_to_negative_center = abs(angle - negative_center);
    float a_negative = 1.0 - smoothstep(in.half_sweep - in.half_border, in.half_sweep + in.half_border, angle_to_negative_center);
    float a_wedge = a_positive + a_negative;

    float a = in.color[3] * a_inner * a_outer * a_wedge;
    if (a == 0) {
        // Discard invisible fragment so it won't show up in stencil operations.
        discard_fragment();
    }
    
    return float4(in.color[0], in.color[1], in.color[2], 1.0);
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
