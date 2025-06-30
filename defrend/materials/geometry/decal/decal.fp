#version 320 es
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/lighting_functions.glsl"

in mediump mat4 mtx_worldview_inv;
in mediump vec3 var_frag_pos;
in mediump vec2 var_texcoord0;

// samplers from the decal
uniform sampler2D diffuse_map;
uniform sampler2D normal_map;
uniform sampler2D spec_glow_map;

// sampler from the g-buffer
uniform sampler2D depth_buffer;

uniform decal_fp {
	mediump vec4 resolution;
    mediump vec4 frustum_corner;
    mediump vec4 frustum_terms;
};

layout(location = 0) out mediump vec4 diffuse_out;
layout(location = 1) out mediump vec4 normal_out;
layout(location = 2) out mediump vec4 spec_glow_out;

mediump mat3 get_tbn_mtx(mediump vec3 view_pos, mediump vec2 texcoord) {
    mediump vec3 d_vd_x = dFdx(view_pos);
    mediump vec3 d_vd_y = dFdy(view_pos);
    mediump vec3 normal = normalize(cross(d_vd_x, d_vd_y));

    mediump vec2 d_tc_x = dFdx(texcoord);
    mediump vec2 d_tc_y = dFdy(texcoord);

    mediump vec3 d_vd_y_cross = cross(d_vd_y, normal);
    mediump vec3 d_vd_x_cross = cross(normal, d_vd_x);

    mediump vec3 tangent = d_vd_y_cross * d_tc_x.x + d_vd_x_cross * d_tc_y.x;
    mediump vec3 bitangent = d_vd_y_cross * d_tc_x.y + d_vd_x_cross * d_tc_y.y;

    mediump float inv_max = inversesqrt(max(dot(tangent, tangent), dot(bitangent, bitangent)));
    return mat3(tangent * inv_max, bitangent * inv_max, normal);
}

mediump vec3 get_perturb_normal(mediump vec2 texture_coord, mediump mat3 tbn_mtx) {
    mediump vec3 normal_map_color = texture(normal_map, texture_coord).xyz;
    mediump vec3 perturb_normal = normal_map_color * 2.0 - 1.0;
    return normalize(tbn_mtx * perturb_normal);
}

void main() {
    // reconstruct the position of the scene fragment that's overlapped by this decal projector fragment
	mediump vec2 texcoord = gl_FragCoord.xy / resolution.xy;
	mediump float depth = texture(depth_buffer, texcoord).r;
    mediump float z = linearizeDepth(depth, frustum_terms.xyz);
    mediump vec4 g_position = vec4(viewPosFromLinearDepth(z, texcoord, frustum_corner.xyz), 1.0);

    // put the scene fragment into model space (i.e., relative to the decal projector box)
    mediump vec4 d_position = mtx_worldview_inv * g_position;
    mediump vec3 abs_pos = abs(d_position.xyz);
    // discard this fragment if it's outside the projector box ([-0.5, 0.5])
    if (abs_pos.x > 0.5 || abs_pos.y  > 0.5 || abs_pos.z > 0.5) discard;

    // if the scene fragment is inside the projector, use its model-space position to sample the decal texture
    d_position += 0.5; // bias [-0.5, 0.5] -> [0, 1]
    mediump vec4 decal_color = texture(diffuse_map, d_position.xy);
    mediump vec4 decal_spec_glow = texture(spec_glow_map, d_position.xy);
    if (decal_color.a == 0.0) discard; // avoid writing normals, etc
    diffuse_out = decal_color;

    // calculate the decal fragment's normal relative to the underlying scene fragment's normal
    mediump mat3 tbn = get_tbn_mtx(g_position.xyz, d_position.xy);
    mediump vec3 decal_normal = get_perturb_normal(d_position.xy, tbn) * 0.5 + 0.5;
    normal_out = vec4(decal_normal, 1);

    spec_glow_out = decal_spec_glow;
}
