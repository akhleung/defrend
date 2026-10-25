#version 420 core
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/lighting_functions.glsl"

#define MAX_PARTITIONS 4

in vec2 var_texcoord0;
in vec3 to_light;

uniform sampler2D depth_buffer;
uniform sampler2D normal_sampler;
uniform sampler2D shadow_atlas;

uniform lighting_fp {
	vec4 frustum_corner;
	vec4 frustum_terms;

	vec4 color; // light color
	
	vec4 shadow_params1; // map resolusion, map dimension, num partitions, transition range
	vec4 shadow_params2; // pcf samples, poisson samples, poisson scale, soft penumbras
	vec4 shadow_params3; // hash factor, hash scale, texel size
	vec4 partitions[MAX_PARTITIONS]; // x offset, y offset, far boundary, bias
	vec4 shadow_tints[MAX_PARTITIONS];
	mat4 mtx_lights[MAX_PARTITIONS]; // (light's proj mtx) * (light's view mtx) * (camera's inverse view mtx)
};

layout(location = 0) out vec4 light_out;

float	SHADOW_MAP_SIZE		= shadow_params1.x;
float	SHADOW_ATLAS_DIM	= shadow_params1.y;
float	SHADOW_MAP_STRIDE	= 1 / SHADOW_ATLAS_DIM;
int		NUM_PARTITIONS		= int(shadow_params1.z);
float	TRANSITION_RANGE	= shadow_params1.w;
int		PCF_SAMPLES			= int(shadow_params2.x);
int		POISSON_SAMPLES		= int(shadow_params2.y);
float	POISSON_SCALE		= shadow_params2.z;
bool	SOFT_PENUMBRAS		= bool(shadow_params2.w);
float	HASH_FACTOR			= shadow_params3.x;
float	HASH_SCALE			= shadow_params3.y;
float	TEXEL_SIZE			= shadow_params3.z;

float	poisson_scale		= POISSON_SCALE * TEXEL_SIZE;
float	hash_scale			= HASH_SCALE * TEXEL_SIZE;

vec2 pcf_kernel[8] = vec2[](
	vec2(-1, 0),
	vec2(1,	0),
	vec2(0, -1),
	vec2(0, 1),
	vec2(-1, -1),
	vec2(1, 1),
	vec2(1, -1),
	vec2(-1, 1)
);

vec2 poisson_disc[16] = vec2[]( 
	vec2(-0.94201624,	-0.39906216),
	vec2(0.94558609,	-0.76890725),
	vec2(-0.094184101,	-0.92938870),
	vec2(0.34495938,	0.29387760),
	vec2(-0.91588581,	0.45771432),
	vec2(-0.81544232,	-0.87912464),
	vec2(-0.38277543,	0.27676845),
	vec2(0.97484398,	0.75648379),
	vec2(0.44323325,	-0.97511554),
	vec2(0.53742981,	-0.47373420),
	vec2(-0.26496911,	-0.41893023),
	vec2(0.79197514,	0.19090188),
	vec2(-0.24188840,	0.99706507),
	vec2(-0.81409955,	0.91437590),
	vec2(0.19984126,	0.78641367),
	vec2(0.14383161,	-0.14100790)
);

float test_poisson_disc(vec2 uv, float occludee_z) {
	if (SOFT_PENUMBRAS) uv += hash22(uv * HASH_FACTOR) * hash_scale;
	float light = POISSON_SAMPLES;
	for (int i = 0; i < POISSON_SAMPLES; ++i) {
		light -= float(texture(shadow_atlas, uv + poisson_disc[i] * poisson_scale).r < occludee_z);
	}
	return light / POISSON_SAMPLES;
}

float shadow_calc(vec4 view_pos_re_cam, vec3 normal, mat4 mtx_light, vec2 offset, float bias) {
	// offset the fragment's view-space position by the surface normal to reduce shadow acne
	view_pos_re_cam = vec4(view_pos_re_cam.xyz + normal * bias, 1);
	// transform the fragment from the camera's view space into the light's clip/screen space
	vec4 proj_pos_re_light = mtx_light * view_pos_re_cam;
	proj_pos_re_light /= proj_pos_re_light.w;
	vec2 shadow_uv = proj_pos_re_light.xy * 0.5 + 0.5; // rescale/bias [-1, 1] -> [0, 1]
	// adjust the shadow uv so that we sample from the correct partition of the cascaded shadow map
	shadow_uv /= SHADOW_ATLAS_DIM;
	shadow_uv += offset;
	shadow_uv = clamp(shadow_uv, offset, offset + SHADOW_MAP_STRIDE);
	// rescale/bias occludee depth and compare to multiple occluder samples from the shadow map (i.e., PCF)
	float occludee_z = proj_pos_re_light.z * 0.5 + 0.5;
	float light = 0;
	for (int i = 0; i < PCF_SAMPLES; ++i) {
		light += test_poisson_disc(shadow_uv + pcf_kernel[i] * TEXEL_SIZE, occludee_z);
	}
	return light / PCF_SAMPLES;
}

void main() {
	vec4 normal_sample	= texture(normal_sampler, var_texcoord0);
	float depth			= texture(depth_buffer, var_texcoord0).r;
	float z				= linearizeDepth(depth, frustum_terms.xyz);
	vec3 var_frag_pos	= viewPosFromLinearDepth(z, var_texcoord0, frustum_corner.xyz);
	vec3 to_camera		= normalize(-var_frag_pos);
	vec3 normal			= normalize(normal_sample.xyz * 2.0 - 1.0); // rescale/bias [0, 1] -> [-1, 1]
	float shininess		= normal_sample.a * 255;

	float shadow = 1;
	vec3 tint = vec3(0);
	float near_edge, far_edge;
	int i;
	for (i = 0, near_edge = 0, far_edge = 0; i < NUM_PARTITIONS; ++i, near_edge = far_edge) {
		vec4 part = partitions[i];
		vec2 offset = part.xy;
		float bias = part.w;
		far_edge = part.z;
		// if this fragment is beyond the far edge of this partition, skip to the next
		if (var_frag_pos.z < -far_edge) continue;
		// otherwise try to cast a shadow using this partition
		shadow = shadow_calc(vec4(var_frag_pos, 1.0), normal, mtx_lights[i], offset, bias);
		tint = shadow_tints[i].rgb;
		// if this fragment isn't near the far edge of this partition, or we're in the last partition, finish here
		float dist = far_edge + var_frag_pos.z;
		if (TRANSITION_RANGE == 0 || dist > TRANSITION_RANGE || i >= NUM_PARTITIONS - 1) break;
		// otherwise, blend with the next partition's shadow for a smooth transition
		vec4 next_part = partitions[i + 1];
		vec2 next_offset = next_part.xy;
		float next_bias = next_part.w;
		float next_shadow = shadow_calc(vec4(var_frag_pos, 1.0), normal, mtx_lights[i + 1], next_offset, next_bias);
		vec3 next_tint = shadow_tints[i + 1].rgb;
		float transition_ratio = dist / TRANSITION_RANGE;
		shadow = mix(next_shadow, shadow, transition_ratio);
		tint = mix(next_tint, tint, transition_ratio);
		// at this point we've tried to cast a shadow using the appropriate partition, so finish here
		break;
	}
	// fade the shadow out towards the end of the last partition
	if (i == NUM_PARTITIONS - 1 && shadow < 1) {
		float fade = smoothstep(mix(near_edge, far_edge, 0.75), far_edge, -var_frag_pos.z);
		shadow += (1.0 - shadow) * fade;
	}
	// because tinting the shadow doesn't really make sense physically (since it's the absence of light), we need to
	// mix the shadow tint with the light color, proportional to the shadow's magnitude
	tint = mix(color.rgb, tint, 1.0 - shadow);

	float diff = diffuse(to_light, normal);
	float spec = specular(to_camera, to_light, normal, shininess);
	// diff = clamp(diff * tint, 0, 1); // consider (ao + 1) / 2
	// spec = clamp(spec * tint, 0, 1);

	// we only support white specular highlights for now, so omit mat_spec
	light_out = normal_sample == vec4(0) ? vec4(0) : clamp(vec4(diff * tint, spec * shadow), 0.0, 1.0);
}
