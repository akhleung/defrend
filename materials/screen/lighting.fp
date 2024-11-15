#version 420 core

#define MAX_LIGHTS 16
#define MAX_PARTITIONS 9

in vec2 var_texcoord0;

uniform sampler2D diffuse_sampler;
uniform sampler2D position_sampler;
uniform sampler2D normal_sampler;
uniform sampler2D ssao_sampler;
uniform sampler2D shadow_sampler;

uniform lighting_fp {
    mat4 mtx_view;
    mat4 mtx_view_inv;
    mat4 mtx_light_view;
    mat4 mtx_light_proj;
    
    vec4 ambient_color;

    vec4 sun_color;
    vec4 sun_direction;
    
    vec4 num_lights;
    vec4 light_positions[MAX_LIGHTS];
    vec4 light_radii[MAX_LIGHTS];
    vec4 light_colors[MAX_LIGHTS];
    vec4 partitions[MAX_PARTITIONS];
    mat4 mtx_light_views[MAX_PARTITIONS];
    mat4 mtx_light_projs[MAX_PARTITIONS];
    vec4 shadow_map_params;
    vec4 shadow_colors[MAX_PARTITIONS];
};

out vec4 frag_color;

float SHADOW_MAP_SIZE = shadow_map_params.x;
float SHADOW_MAP_DIM = shadow_map_params.z;
float SHADOW_TEXEL_SIZE = shadow_map_params.w;

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
    float falloff = 1.0 - smoothstep(r_inner, r_outer, d);
    return falloff * falloff;
}

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

float shadow_calc(vec4 view_pos_re_cam, vec3 normal, mat4 mtx_light_view, mat4 mtx_light_proj, float x_offset, float y_offset, float bias) {
    // 1. offset fragment view-space position by surface normal to reduce shadow acne
    view_pos_re_cam = vec4(view_pos_re_cam.xyz + normal * bias, 1);
    // 2. multiply fragment view-space position by inverse view matrix of camera to get world space position
    vec4 world_pos = mtx_view_inv * view_pos_re_cam;
    // 3. multiply by view matrix of light to get view-space position of fragment relative to light
    vec4 view_pos_re_light = mtx_light_view * world_pos;
    // 4. multiply by proj matrix of light to get clip/screen-space position of fragment relative to light
    vec4 proj_pos_re_light = mtx_light_proj * view_pos_re_light;
    proj_pos_re_light /= proj_pos_re_light.w;
    vec2 shadow_texcoord0 = proj_pos_re_light.xy * 0.5 + 0.5;
    // 5. adjust the shadow uv so that we sample from the correct partition of the cascaded shadow map
    shadow_texcoord0 /= SHADOW_MAP_DIM;
    shadow_texcoord0.x += x_offset;
    shadow_texcoord0.y += y_offset;
    // short circuit with no shadow if the rendering exceeds the shadow map boundaries
    float upper_bound = 1/SHADOW_MAP_DIM;
    if (shadow_texcoord0.x < x_offset || shadow_texcoord0.x > upper_bound + x_offset || 
        shadow_texcoord0.y < y_offset || shadow_texcoord0.y > upper_bound + y_offset) {
        return 1.0;
    } 
    // 6. re-normalize occludee depth and compare to multiple occluder samples from the shadow map (i.e., PCF)
    float shadow = 0.0;
    float occludee_z = proj_pos_re_light.z * 0.5 + 0.5;
    for (int x = -1; x <= 1; ++x) {
        for (int y = -1; y <= 1; ++y) {
            vec2 uv = shadow_texcoord0 + vec2(x,y) * SHADOW_TEXEL_SIZE;
            float occluder_z = texture(shadow_sampler, uv + rand(uv)).r;
            shadow += occluder_z < occludee_z ? 0.0 : 1.0;
        }
    }
    shadow /= 9.0; // divide by number of samples
    return shadow;
}

void main() {

    vec4 position_sample = texture(position_sampler, var_texcoord0);
    vec4 normal_sample = texture(normal_sampler, var_texcoord0);

    vec3 var_frag_pos = position_sample.xyz;
    vec3 view_dir = normalize(-var_frag_pos);
    vec3 normal = normal_sample.xyz * 2.0 - 1.0;

    float ao = texture(ssao_sampler, var_texcoord0).r;
    float shininess = position_sample.w;
    vec4 mat_spec = vec4(normal_sample.w, normal_sample.w, normal_sample.w, 1.0);
    vec4 mat_diff = texture(diffuse_sampler, var_texcoord0);

    vec4 color = ambient_color * mat_diff * ao;

    // directional (i.e., sun) light
    vec3 sun_dir = mat3(mtx_view) * normalize(-sun_direction.xyz);
    sun_dir = normalize(sun_dir);

    int num_partitions = int(partitions[0].w);
    float shadow = 1.0;
    for (int i = 0; i < num_partitions; ++i) {
        float cutoff = -partitions[i].z;
        if (var_frag_pos.z > cutoff) {
            // cast a shadow using the i'th shadow map
            float x_offset = partitions[i].x / SHADOW_MAP_SIZE / SHADOW_MAP_DIM;
            float y_offset = partitions[i].y / SHADOW_MAP_SIZE / SHADOW_MAP_DIM;
            mat4 mtx_light_proj = mtx_light_projs[i];
            mat4 mtx_light_view = mtx_light_views[i];
            shadow = shadow_calc(vec4(var_frag_pos, 1.0), normal, mtx_light_view, mtx_light_proj, x_offset, y_offset, 0.25 + i * 0.05);
            break;
        }
    }

    float sun_spec = specular(view_dir, sun_dir, normal, shininess) * shadow;
    float sun_diff = diffuse(sun_dir, normal) * (ao /* * 0.5 + 0.5 */) * shadow;
    color += (sun_diff * mat_diff + sun_spec * mat_spec) * sun_color;

    for (int i = 0; i < num_lights.x; ++i) {
        vec4 light_pos = mtx_view * light_positions[i];
        vec3 light_dir = light_direction(var_frag_pos, light_pos.xyz);
        float spec = specular(view_dir, light_dir, normal, shininess);
        float diff = diffuse(light_dir, normal);
        float attn = attenuation(var_frag_pos, light_pos.xyz, light_radii[i]);
        color += (diff * mat_diff + spec * mat_spec) * light_colors[i] * attn;
    }

    color.a = mat_diff.a;
    // color = vec4(ao, ao, ao, 1.0);
    // vec4 shadow_sample = texture(shadow_sampler, var_texcoord0);
    // color = vec4(shadow_sample.r, shadow_sample.r, shadow_sample.r, 1.0);
    frag_color = clamp(color, 0.0, 1.0);
}
