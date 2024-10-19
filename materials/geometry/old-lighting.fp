#version 420 core

#define MAX_LIGHTS 16

in vec3 var_frag_pos;
in vec3 var_normal;
in vec2 var_texcoord0;

uniform sampler2D diffuse_map;
uniform sampler2D normal_map;
uniform sampler2D specular_map;

uniform model_fp {
    mat4 mtx_view;
    
    vec4 ambient_color;

    vec4 sun_color;
    vec4 sun_direction;
    
    vec4 num_lights;
    vec4 light_positions[MAX_LIGHTS];
    vec4 light_radii[MAX_LIGHTS];
    vec4 light_colors[MAX_LIGHTS];

    vec4 shininess;
};

layout(location = 0) out vec4 color_out;
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
    vec3 perturb_normal = normal_map_color * 2.0 - vec3(1.0);
    // if (surface.z > 0.5) {
    //     // This is the DirectX normals map format
    //     perturb_normal.y = -perturb_normal.y;
    // }
    return normalize(tbn_mtx * perturb_normal);
}

vec3 light_direction(vec3 frag_pos, vec3 light_pos) {
    return normalize(light_pos - frag_pos);
}

float diffuse(vec3 light_dir, vec3 normal) {
    return max(dot(normal, light_dir), 0.0);
}

float attenuation(vec3 frag_pos, vec3 light_pos, vec4 light_radii) {
    float r_inner = light_radii.x;
    float r_outer = light_radii.y;
    float d = distance(frag_pos, light_pos);
    // float falloff = clamp((r_outer - d) / (r_outer - r_inner), 0.0, 1.0);
    float falloff = 1.0 - smoothstep(r_inner, r_outer, d);
    return falloff * falloff;
}

float specular(vec3 view_dir, vec3 light_dir, vec3 normal) {
    vec3 r = reflect(-light_dir, normal); // TODO: fix this
    return max(dot(r, normal), 0.0);
}

void main() {
    vec3 view_dir = normalize(-var_frag_pos);
    // vec4 mat_spec = vec4(shininess.xyz, 1.0);
    vec4 mat_spec = vec4(texture(specular_map, var_texcoord0).xyz, 1.0);
    float spec_exp = shininess.w;

    mat3 tbn = get_tbn_mtx();

    vec4 mat_diff = texture(diffuse_map, var_texcoord0);
    vec3 normal = get_perturb_normal(var_texcoord0, tbn);

    // implement ambient light as directional, always shining directly on the face (i.e., into the interpolated normal)
    vec4 color = diffuse(var_normal, normal) * ambient_color * mat_diff;

    // directional (i.e., sun) light
    vec3 sun_dir = mat3(mtx_view) * normalize(-sun_direction.xyz);
    float sun_spec = specular(view_dir, sun_dir, normal);
    float sun_diff = diffuse(sun_dir, normal);
    color += (sun_diff * mat_diff + pow(sun_spec, spec_exp) * mat_spec) * sun_color;

    for (int i = 0; i < num_lights.x; ++i) {
        vec4 light_pos = mtx_view * light_positions[i];
        vec3 light_dir = light_direction(var_frag_pos, light_pos.xyz);
        float spec = specular(view_dir, light_dir, normal);
        float diff = diffuse(light_dir, normal);
        float attn = attenuation(var_frag_pos, light_pos.xyz, light_radii[i]);
        color += (diff * mat_diff + pow(spec, spec_exp) * mat_spec) * light_colors[i] * attn;
    }

    color.a = mat_diff.a;

    color_out = clamp(color, 0.0, 1.0);
    position_out = vec4(var_frag_pos, 1.0);
    normal_out = vec4(normal, 1.0);
}
