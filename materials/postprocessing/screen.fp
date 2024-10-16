#version 420 core

#define MAX_LIGHTS 16
#define SHADOW_MAP_SIZE 2048.0

in vec2 var_texcoord0;

uniform sampler2D diffuse_sampler;
uniform sampler2D position_sampler;
uniform sampler2D normal_sampler;
uniform sampler2D ssao_sampler;
uniform sampler2D shadow_sampler;

uniform screen_fp {
    mat4 mtx_view;
    mat4 mtx_view_inv;
    mat4 mtx_shadow;
    mat4 mtx_shadow_view;
    mat4 mtx_shadow_proj;
    
    vec4 ambient_color;

    vec4 sun_color;
    vec4 sun_direction;
    
    vec4 num_lights;
    vec4 light_positions[MAX_LIGHTS];
    vec4 light_radii[MAX_LIGHTS];
    vec4 light_colors[MAX_LIGHTS];
};

out vec4 frag_color;

vec3 light_direction(vec3 frag_pos, vec3 light_pos) {
    return normalize(light_pos - frag_pos);
}

float diffuse(vec3 light_dir, vec3 normal_sample) {
    return max(dot(normal_sample, light_dir), 0.0);
}

float attenuation(vec3 frag_pos, vec3 light_pos, vec4 light_radii) {
    float r_inner = light_radii.x;
    float r_outer = light_radii.y;
    float d = distance(frag_pos, light_pos);
    // float falloff = clamp((r_outer - d) / (r_outer - r_inner), 0.0, 1.0);
    float falloff = 1.0 - smoothstep(r_inner, r_outer, d);
    return falloff * falloff;
}

// Blinn-Phong optimized specular lighting (faster, but more approximate)
// float specular(vec3 viewdir, vec3 lightdir, vec3 norm, float shiny) {
//     vec3 H = normalize(viewdir + lightdir);
//     float HdotN = max(0.0, dot(H, norm));
//     return pow(HdotN, shiny);
// }

// Classic Phong specular lighting (slower, but more accurate)
float specular(vec3 viewdir, vec3 lightdir, vec3 norm, float shiny) {
    vec3 R = reflect(-lightdir, norm);
    return pow(max(dot(R, viewdir), 0.0), shiny);
}

vec2 rand(vec2 co) {
    return vec2(
        fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453),
        fract(sin(dot(co.yx ,vec2(12.9898,78.233))) * 43758.5453)
    ) * 0.00047;
}

float shadow_calc(vec4 view_pos_re_cam, float bias) {
    // 1. multiply fragment view position by inverse view matrix of camera to get world space position
    vec4 world_pos = mtx_view_inv * view_pos_re_cam;
    // 2. multiply by view matrix of light to get view space position of fragment relative to light
    vec4 view_pos_re_light = mtx_shadow_view * world_pos;
    // 3. multiply by proj matrix of light to get clip/screen position of fragment relative to light
    vec4 proj_pos_re_light = mtx_shadow_proj * view_pos_re_light;
    proj_pos_re_light /= proj_pos_re_light.w;
    vec2 shadow_texcoord0 = proj_pos_re_light.xy * 0.5 + 0.5;

    float shadow = 0.0;
    float texel_size = 1.0 / SHADOW_MAP_SIZE;
    float occludee_z = proj_pos_re_light.z * 0.5 + 0.5;
    for (int x = -1; x <= 1; ++x) {
        for (int y = -1; y <= 1; ++y) {
            vec2 uv = shadow_texcoord0 + vec2(x,y) * texel_size;
            float occluder_z = texture(shadow_sampler, uv + rand(uv)).r + bias;
            if (occluder_z < occludee_z) {
                continue;
            } else {
                shadow += 1.0;
            }
        }
    }
    shadow /= 9.0;

    // since we can't clamp-to-border in Defold, default to no shadows if the rendering exceeds the shadowmap boundaries
    if (shadow_texcoord0.x < 0) shadow = 1;
    if (shadow_texcoord0.x > 1) shadow = 1;
    if (shadow_texcoord0.y < 0) shadow = 1;
    if (shadow_texcoord0.y > 1) shadow = 1;

    return shadow;

    // // 4. sample from shadow_sampler using coord from step 3
    // float occluder_z = texture(shadow_sampler, shadow_texcoord0).r + bias;
    // // 5. compare sampled z from step 4 to z from step 2 to determine if fragment is shadowed
    // float occludee_z = proj_pos_re_light.z * 0.5 + 0.5;
    // if (occluder_z < occludee_z) {
    //     return 0.0;
    // } else {
    //     return 1.0;
    // }
}

void main() {

    vec4 position_sample = texture(position_sampler, var_texcoord0);
    vec4 normal_sample = texture(normal_sampler, var_texcoord0);

    vec3 var_frag_pos = position_sample.xyz;
    vec3 view_dir = normalize(-var_frag_pos);

    vec4 mat_spec = vec4(normal_sample.w, normal_sample.w, normal_sample.w, 1.0);
    float spec_exp = position_sample.w;

    vec4 mat_diff = texture(diffuse_sampler, var_texcoord0);
    vec3 normal = normal_sample.xyz;

	frag_color = texture(ssao_sampler, var_texcoord0);

    float ao = texture(ssao_sampler, var_texcoord0).x;
    float blur = texture(ssao_sampler, var_texcoord0).y;
    ao = blur * ao;

    vec4 color = ambient_color * mat_diff * ao;

    // directional (i.e., sun) light
    vec3 sun_dir = mat3(mtx_view) * normalize(-sun_direction.xyz);
    sun_dir = normalize(sun_dir);
    float d = dot(normal, sun_dir);
    float bias = (1.0 - d) * 0.005;
    float shadow = shadow_calc(vec4(var_frag_pos, 1.0), bias);
    float sun_spec = specular(view_dir, sun_dir, normal, spec_exp) * shadow;
    float sun_diff = diffuse(sun_dir, normal) * ao * shadow;
    color += (sun_diff * mat_diff + sun_spec * mat_spec) * sun_color;

    for (int i = 0; i < num_lights.x; ++i) {
        vec4 light_pos = mtx_view * light_positions[i];
        vec3 light_dir = light_direction(var_frag_pos, light_pos.xyz);
        float spec = specular(view_dir, light_dir, normal, spec_exp);
        float diff = diffuse(light_dir, normal);
        float attn = attenuation(var_frag_pos, light_pos.xyz, light_radii[i]);
        color += (diff * mat_diff + spec * mat_spec) * light_colors[i] * attn;
    }

    color.a = mat_diff.a;
    // color = texture(ssao_sampler, var_texcoord0);
    // color = vec4(blur, blur, blur, 1.0);
    // vec4 shadow_sample = texture(shadow_sampler, var_texcoord0);
    // color = vec4(shadow_sample.r, shadow_sample.r, shadow_sample.r, 1.0);
    frag_color = clamp(color, 0.0, 1.0);
}
