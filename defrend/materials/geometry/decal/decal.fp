#version 420 core
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/lighting_functions.glsl"

in mat4 mtx_worldview_inv;
in vec3 var_frag_pos;
in vec2 var_texcoord0;
#ifdef EDITOR
in vec3 var_vertex;
#endif

// samplers from the decal
uniform sampler2D diffuse_map;
uniform sampler2D normal_map;
uniform sampler2D spec_glow_map;

// sampler from the g-buffer
uniform sampler2D depth_buffer;

uniform decal_fp {
	vec4 resolution;
    vec4 frustum_corner;
    vec4 frustum_terms;
};

layout(location = 0) out vec4 diffuse_out;
layout(location = 1) out vec4 normal_out;
layout(location = 2) out vec4 spec_glow_out;

mat3 get_tbn_mtx(vec3 view_pos, vec2 texcoord) {
    vec3 d_vd_x = dFdx(view_pos);
    vec3 d_vd_y = dFdy(view_pos);
    vec3 normal = normalize(cross(d_vd_x, d_vd_y));

    vec2 d_tc_x = dFdx(texcoord);
    vec2 d_tc_y = dFdy(texcoord);

    vec3 d_vd_y_cross = cross(d_vd_y, normal);
    vec3 d_vd_x_cross = cross(normal, d_vd_x);

    vec3 tangent = d_vd_y_cross * d_tc_x.x + d_vd_x_cross * d_tc_y.x;
    vec3 bitangent = d_vd_y_cross * d_tc_x.y + d_vd_x_cross * d_tc_y.y;

    float inv_max = inversesqrt(max(dot(tangent, tangent), dot(bitangent, bitangent)));
    return mat3(tangent * inv_max, bitangent * inv_max, normal);
}

vec3 get_perturb_normal(vec2 texture_coord, mat3 tbn_mtx) {
    vec3 normal_map_color = texture(normal_map, texture_coord).xyz;
    vec3 perturb_normal = normal_map_color * 2.0 - 1.0;
    return normalize(tbn_mtx * perturb_normal);
}

void main() {
    // reconstruct the position of the scene fragment that's overlapped by this decal projector fragment
	vec2 texcoord = gl_FragCoord.xy / resolution.xy;
	float depth = rgba_to_float(texture(depth_buffer, texcoord));
    float z = linearizeDepth(depth, frustum_terms.xyz);
    vec4 g_position = vec4(viewPosFromLinearDepth(z, texcoord, frustum_corner.xyz), 1.0);

    // put the scene fragment into model space (i.e., relative to the decal projector box)
    vec4 d_position = mtx_worldview_inv * g_position;
    vec3 abs_pos = abs(d_position.xyz);
    // discard this fragment if it's outside the projector box ([-0.5, 0.5])
    if (abs_pos.x > 0.5 || abs_pos.y  > 0.5 || abs_pos.z > 0.5) discard;

    // if the scene fragment is inside the projector, use its model-space position to sample the decal texture
    d_position += 0.5; // bias [-0.5, 0.5] -> [0, 1]
    vec4 decal_color = texture(diffuse_map, d_position.xy);
    vec4 decal_spec_glow = texture(spec_glow_map, d_position.xy);
    if (decal_color.a == 0) discard; // avoid writing normals, etc
    diffuse_out = decal_color;

    // calculate the decal fragment's normal relative to the underlying scene fragment's normal
    mat3 tbn = get_tbn_mtx(g_position.xyz, d_position.xy);
    vec3 decal_normal = get_perturb_normal(d_position.xy, tbn) * 0.5 + 0.5;
    normal_out = vec4(decal_normal, 1);

    spec_glow_out = decal_spec_glow;

	#ifdef EDITOR // visualization for viewing decal projector boxes in the editor
    vec3 v = abs(var_vertex);
    float edge = 0.4825;
    vec3 v100 = floor(v * 100);
    vec3 vf = fract(v100 / 10);
    float line_thickness = 0.2;
    if (var_vertex.z == -0.5) {
        diffuse_out = texture(diffuse_map, var_texcoord0);
    } else if (v.x > edge && v.y > edge || v.y > edge && v.z > edge || v.x > edge && v.z > edge) {
		diffuse_out = vec4(1);
	} else if (vf.x < line_thickness && vf.y < line_thickness) {
        diffuse_out = vec4(1);
    } else {
		discard;
	}
	#endif
}
