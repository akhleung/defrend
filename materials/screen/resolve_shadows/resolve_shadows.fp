#version 420 core
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/lighting_functions.glsl"

#define MAX_PARTITIONS 9

in vec2 var_texcoord0;

uniform sampler2D depth_buffer;
uniform sampler2D normal_sampler;
uniform sampler2D ssao_sampler;
uniform sampler2D shadow_sampler;

uniform resolve_shadows_fp {
    mat4 mtx_view;
    vec4 frustum_corner;
    vec4 frustum_terms;
    vec4 directional_to;

    vec4 camera_partitions[MAX_PARTITIONS];
    mat4 mtx_lights[MAX_PARTITIONS]; // (light's proj mtx) * (light's view mtx) * (camera's inverse view mtx)
    vec4 shadow_params;
    vec4 shadow_colors[MAX_PARTITIONS];
};

layout(location = 0) out vec4 shadow_out;
layout(location = 1) out float depth_out;

float SHADOW_MAP_SIZE = shadow_params.x;
float SHADOW_MAP_DIM = shadow_params.y;
float SHADOW_BOUNDARY = 1/SHADOW_MAP_DIM;
int SHADOW_SOFTNESS = int(shadow_params.z);
int NUM_PARTITIONS = int(shadow_params.w);

float softener = 0.00043 * SHADOW_SOFTNESS;
vec3 directional_from = normalize(mat3(mtx_view) * -directional_to.xyz);

float shadow_calc(vec4 view_pos_re_cam, vec3 normal, mat4 mtx_light, vec2 offset, float bias) {
	float light_orientation = dot(normal, directional_from);
	float b = light_orientation > 0 ? bias : 0;
    // offset the fragment's view-space position by the surface normal to reduce shadow acne
    view_pos_re_cam = vec4(view_pos_re_cam.xyz + normal * b, 1);
    // transform the fragment from the camera's view space into the light's clip/screen space
    vec4 proj_pos_re_light = mtx_light * view_pos_re_cam;
    proj_pos_re_light /= proj_pos_re_light.w;
    vec2 shadow_texcoord0 = proj_pos_re_light.xy * 0.5 + 0.5; // rescale/bias [-1, 1] -> [0, 1]
    // adjust the shadow uv so that we sample from the correct partition of the cascaded shadow map
    shadow_texcoord0 /= SHADOW_MAP_DIM;
    shadow_texcoord0 += offset;
    // short circuit with no shadow if the rendering exceeds the shadow map boundaries
    if (shadow_texcoord0.x < offset.x || shadow_texcoord0.x > SHADOW_BOUNDARY + offset.x || 
        shadow_texcoord0.y < offset.y || shadow_texcoord0.y > SHADOW_BOUNDARY + offset.y) {
        return 1.0;
    } 
    // rescale/bias occludee depth and compare to multiple occluder samples from the shadow map (i.e., PCF)
    float shadow = 0.0;
    float occludee_z = proj_pos_re_light.z * 0.5 + 0.5;
    int samples = 0;
    for (int x = -SHADOW_SOFTNESS; x <= SHADOW_SOFTNESS; ++x) {
        for (int y = -SHADOW_SOFTNESS; y <= SHADOW_SOFTNESS; ++y) {
            vec2 uv = shadow_texcoord0 + vec2(x,y) / SHADOW_MAP_SIZE;
            float occluder_z = texture(shadow_sampler, uv /* + hash22(uv * 100000) * softener */).r;
            shadow += occluder_z < occludee_z ? 0.0 : 1.0;
            ++samples;
        }
    }
    return shadow / samples;
}

void main() {

    vec4 normal_sample = texture(normal_sampler, var_texcoord0);

    float depth    = texture(depth_buffer, var_texcoord0).r;
    float z        = linearizeDepth(depth, frustum_terms.xyz);
    vec3 var_frag_pos = viewPosFromLinearDepth(z, var_texcoord0, frustum_corner.xyz);
    vec3 view_dir = normalize(-var_frag_pos);
    vec3 normal = normalize(normal_sample.xyz * 2.0 - 1.0); // rescale/bias [0, 1] -> [-1, 1]

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
        float fade = smoothstep(mix(prev_cutoff, this_cutoff, 0.75), this_cutoff, -var_frag_pos.z);
        shadow += (1.0 - shadow) * fade;
    }

    float ao = texture(ssao_sampler, var_texcoord0).a;

	float occlusion = shadow * ao;
	shadow_out = vec4(depth < 1 ? occlusion : 0);
	depth_out = occlusion < 1 ? depth : 1;
}
