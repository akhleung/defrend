#version 420 core

in mat4 mtx_worldview_inv;
in vec3 var_frag_pos;
in vec2 var_texcoord0;

// samplers from the decal
uniform sampler2D diffuse_map;
uniform sampler2D normal_map;
// uniform sampler2D specular_map;

// sampler from the g-buffer
uniform sampler2D depth_buffer;

uniform decal_fp {
	vec4 resolution;
    vec4 frustum_corner;
    vec4 frustum_terms;
};

layout(location = 0) out vec4 diffuse_out;
layout(location = 1) out vec4 normal_out;

float linearizeDepth(float d) {
    float zNdc  = 2.0 * d - 1.0;
    return 2.0 * frustum_terms.x / (frustum_terms.y - zNdc * (frustum_terms.z));
}

vec3 viewPosFromLinearDepth(float z, vec2 uv) {
    vec2  uvNdc = 2.0 * uv - 1.0;
    vec2  xyFar = frustum_corner.xy * uvNdc;
    float zNorm = z / frustum_corner.z;
    return vec3(xyFar * zNorm, z);
}

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
	float depth = texture(depth_buffer, texcoord).r;
    float z = linearizeDepth(depth);
    vec4 g_position = vec4(viewPosFromLinearDepth(z, texcoord), 1.0);

    // put the scene fragment into model space (i.e., relative to the decal projector box)
    vec4 d_position = mtx_worldview_inv * g_position;
    vec3 abs_pos = abs(d_position.xyz);
    // discard this fragment if it's outside the projector box ([-0.5, 0.5])
    if (abs_pos.x > 0.5 || abs_pos.y  > 0.5 || abs_pos.z > 0.5) discard;

    // if the scene fragment is inside the projector, use its model-space position to sample the decal texture
    d_position += 0.5; // bias [-0.5, 0.5] -> [0, 1]
    vec4 decal_color = texture(diffuse_map, d_position.xy);
    if (decal_color.a == 0) discard;
    diffuse_out = decal_color;
    diffuse_out.a = 1;

    // calculate the decal fragment's normal relative to the underlying scene fragment's normal
    mat3 tbn = get_tbn_mtx(g_position.xyz, d_position.xy);
    vec3 decal_normal = get_perturb_normal(d_position.xy, tbn) * 0.5 + 0.5;
    normal_out = vec4(decal_normal, 1);
}
