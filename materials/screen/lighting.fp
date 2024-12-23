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
    
    vec4 light_params;
    vec4 ambient_color;
    vec4 directional_color;
    vec4 directional_to;
    
    vec4 num_lights;
    vec4 light_positions[MAX_LIGHTS];
    vec4 light_radii[MAX_LIGHTS];
    vec4 light_colors[MAX_LIGHTS];
    vec4 camera_partitions[MAX_PARTITIONS];
    mat4 mtx_lights[MAX_PARTITIONS]; // (light's proj mtx) * (light's view mtx) * (camera's inverse view mtx)
    vec4 shadow_params;
    vec4 shadow_colors[MAX_PARTITIONS];
};

out vec4 frag_color;

float SHADOW_MAP_SIZE = shadow_params.x;
float SHADOW_MAP_DIM = shadow_params.y;
float SHADOW_BOUNDARY = 1/SHADOW_MAP_DIM;
int SHADOW_SOFTNESS = int(shadow_params.z);
int NUM_PARTITIONS = int(shadow_params.w);
vec3 directional_from = normalize(mat3(mtx_view) * -directional_to.xyz);

vec3 light_direction(vec3 frag_pos, vec3 light_pos) {
    return normalize(light_pos - frag_pos);
}

float diffuse(vec3 to_light, vec3 normal_sample) {
    return max(dot(normal_sample, to_light), 0.0);
}

float attenuation(vec3 frag_pos, vec3 light_pos, vec4 light_radii) {
    float r_inner = light_radii.x;
    float r_outer = light_radii.y;
    float d = distance(frag_pos, light_pos);
    float falloff = 1.0 - smoothstep(r_inner, r_outer, d);
    return falloff * falloff;
}

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

float shadow_calc(vec4 view_pos_re_cam, vec3 normal, mat4 mtx_light, vec2 offset, float bias) {
    // offset the fragment's view-space position by the surface normal to reduce shadow acne
    view_pos_re_cam = vec4(view_pos_re_cam.xyz + normal * bias, 1);
    // transform the fragment from the camera's view space into the light's clip/screen space
    vec4 proj_pos_re_light = mtx_light * view_pos_re_cam;
    proj_pos_re_light /= proj_pos_re_light.w;
    vec2 shadow_texcoord0 = proj_pos_re_light.xy * 0.5 + 0.5; // rescale [-1, 1] -> [0, 1]
    // adjust the shadow uv so that we sample from the correct partition of the cascaded shadow map
    shadow_texcoord0 /= SHADOW_MAP_DIM;
    shadow_texcoord0 += offset;
    // rescale occludee depth and compare to multiple occluder samples from the shadow map (i.e., PCF)
    float shadow = 1.0;
    float occludee_z = proj_pos_re_light.z * 0.5 + 0.5;
    int samples = 0;
    for (int x = -SHADOW_SOFTNESS; x <= SHADOW_SOFTNESS; ++x) {
        for (int y = -SHADOW_SOFTNESS; y <= SHADOW_SOFTNESS; ++y) {
            vec2 uv = shadow_texcoord0 + vec2(x,y) / SHADOW_MAP_SIZE;
            float occluder_z = texture(shadow_sampler, uv + rand(uv) * SHADOW_SOFTNESS * 0).r;
            shadow += occluder_z < occludee_z ? 0.0 : 1.0;
            ++samples;
        }
    }
    return shadow / samples;
}

void main() {

    vec4 position_sample = texture(position_sampler, var_texcoord0);
    vec4 normal_sample = texture(normal_sampler, var_texcoord0);

    vec3 var_frag_pos = position_sample.xyz;
    vec3 view_dir = normalize(-var_frag_pos);
    vec3 normal = normal_sample.xyz * 2.0 - 1.0; // rescale [0, 1] -> [-1, 1]

    float shadow = 1;
    float this_cutoff = 0;
    float prev_cutoff = 0;
    int i = 0;
    while (i < NUM_PARTITIONS) {
        vec4 part = camera_partitions[i];
        this_cutoff = part.z;
        if (var_frag_pos.z > -this_cutoff) { // cast a shadow using the nearest applicable partition
            shadow = shadow_calc(vec4(var_frag_pos, 1.0), normal, mtx_lights[i], part.xy, part.w);
            break;
        }
        prev_cutoff = this_cutoff;
        ++i;
    }
    if (i == NUM_PARTITIONS - 1 && shadow < 1) { // fade the shadow out as it reaches the end of the last partition
        float interval = this_cutoff - prev_cutoff;
        float fade = smoothstep(prev_cutoff + interval * 0.75, this_cutoff, -var_frag_pos.z);
        float diff = 1.0 - shadow;
        shadow += diff * fade;
    }

    float ao = texture(ssao_sampler, var_texcoord0).r;
    float shininess = position_sample.w;
    vec4 mat_spec = vec4(normal_sample.w, normal_sample.w, normal_sample.w, 1.0);
    vec4 mat_diff = texture(diffuse_sampler, var_texcoord0);
    vec4 color = ambient_color * mat_diff * ao;
    float sun_spec = specular(view_dir, directional_from, normal, shininess) * shadow;
    float sun_diff = diffuse(directional_from, normal) * (ao /* * 0.5 + 0.5 */) * shadow;
    color += (sun_diff * mat_diff + sun_spec * mat_spec) * directional_color;

    for (int i = 0; i < num_lights.x; ++i) {
        vec4 light_pos = mtx_view * light_positions[i];
        vec3 to_light = light_direction(var_frag_pos, light_pos.xyz);
        float spec = specular(view_dir, to_light, normal, shininess);
        float diff = diffuse(to_light, normal);
        float attn = attenuation(var_frag_pos, light_pos.xyz, light_radii[i]);
        color += (diff * mat_diff + spec * mat_spec) * light_colors[i] * attn;
    }

    color.a = mat_diff.a;
    // color = vec4(ao, ao, ao, 1.0);
    // vec4 shadow_sample = texture(shadow_sampler, var_texcoord0);
    // color = vec4(shadow_sample.r, shadow_sample.r, shadow_sample.r, 1.0);
    frag_color = clamp(color, 0.0, 1.0);
}
