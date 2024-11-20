#version 420 core

in vec3 var_frag_pos;
in vec3 var_normal;
in vec2 var_texcoord0;

uniform sampler2D diffuse_map;
uniform sampler2D normal_map;
uniform sampler2D specular_map;

layout(location = 0) out vec4 diffuse_out;
layout(location = 1) out vec4 position_out;
layout(location = 2) out vec4 normal_out;

mat3 get_tbn_mtx() {
    vec3 d_vd_x = dFdx(var_frag_pos);
    vec3 d_vd_y = dFdy(var_frag_pos);

    vec2 d_tc_x = dFdx(var_texcoord0);
    vec2 d_tc_y = dFdy(var_texcoord0);

    vec3 d_vd_y_cross = cross(d_vd_y, var_normal);
    vec3 d_vd_x_cross = cross(var_normal, d_vd_x);

    vec3 tangent = d_vd_y_cross * d_tc_x.x + d_vd_x_cross * d_tc_y.x;
    vec3 bitangent = d_vd_y_cross * d_tc_x.y + d_vd_x_cross * d_tc_y.y;

    float inv_max = inversesqrt(max(dot(tangent, tangent), dot(bitangent, bitangent)));
    return mat3(tangent * inv_max, bitangent * inv_max, var_normal);
}

vec3 get_perturb_normal(vec2 texture_coord, mat3 tbn_mtx) {
    // mediump mat3 tbn_mtx = get_tbn_mtx(world_normal, -view_direction, texture_coord);
    vec3 normal_map_color = texture(normal_map, texture_coord).xyz;
    // mediump vec3 perturb_normal = normal_map_color * (255.0 / 127.0) - vec3(128.0 / 127.0);
    vec3 perturb_normal = normal_map_color * 2.0 - 1.0;
    // if (surface.z > 0.5) {
    //     // This is the DirectX normals map format
    //     perturb_normal.y = -perturb_normal.y;
    // }
    return normalize(tbn_mtx * perturb_normal);
}

void main() {
    vec4 mat_diff = texture(diffuse_map, var_texcoord0);
    vec4 mat_spec = texture(specular_map, var_texcoord0);

    mat3 tbn = get_tbn_mtx();
    vec3 normal = get_perturb_normal(var_texcoord0, tbn) * 0.5 + 0.5;

    diffuse_out = mat_diff;
    position_out = vec4(var_frag_pos, mat_spec.w);
    normal_out = vec4(normal, mat_spec.r);
}
