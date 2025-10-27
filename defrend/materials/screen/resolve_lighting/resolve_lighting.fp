#version 420 core
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/lighting_functions.glsl"

#define MAX_PARTITIONS 4

in vec2 var_texcoord0;
in vec3 directional_from;

uniform sampler2D diffuse_sampler;
uniform sampler2D depth_buffer;
uniform sampler2D normal_sampler;
uniform sampler2D spec_glow_sampler;
uniform sampler2D ssao_sampler;
uniform sampler2D shadow_sampler;
uniform sampler2D light_sampler;

uniform lighting_fp {
	vec4 frustum_corner;
	vec4 frustum_terms;

	vec4 fog_params;
	vec4 fog_color;
	vec4 ambient_color;
	vec4 directional_color;
	
	vec4 camera_partitions[MAX_PARTITIONS];
	mat4 mtx_lights[MAX_PARTITIONS]; // (light's proj mtx) * (light's view mtx) * (camera's inverse view mtx)
	vec4 shadow_params1;
	vec4 shadow_params2;
	vec4 shadow_colors[MAX_PARTITIONS];
};

layout(location = 0) out vec4 frag_color;

float FOG_NEAR		= fog_params.x;
float FOG_FAR		= fog_params.y;

float   SHADOW_MAP_SIZE     = shadow_params1.x;
float   SHADOW_MAP_DIM      = shadow_params1.y;
float   SHADOW_BOUNDARY     = 1/SHADOW_MAP_DIM;
float   POISSON_SCALE       = shadow_params1.z;
int		POISSON_SAMPLES		= int(shadow_params1.w);
int		PCF_SAMPLES			= int(shadow_params2.x);
bool	SOFT_PENUMBRAS		= bool(shadow_params2.y);
int     NUM_PARTITIONS      = int(shadow_params2.z);
float	TRANSITION_RANGE	= shadow_params2.w;

vec2 pcf_kernel[8] = vec2[](
	vec2(-1, 0)		/ SHADOW_MAP_SIZE,
	vec2(1,	0)		/ SHADOW_MAP_SIZE,
	vec2(0, -1)		/ SHADOW_MAP_SIZE,
	vec2(0, 1)		/ SHADOW_MAP_SIZE,
	vec2(-1, -1)	/ SHADOW_MAP_SIZE,
	vec2(1, 1)		/ SHADOW_MAP_SIZE,
	vec2(1, -1)		/ SHADOW_MAP_SIZE,
	vec2(-1, 1)		/ SHADOW_MAP_SIZE
);

vec2 poisson_disc[16] = vec2[]( 
	vec2(-0.94201624,	-0.39906216)	/ POISSON_SCALE, 
	vec2(0.94558609,	-0.76890725)	/ POISSON_SCALE, 
	vec2(-0.094184101,	-0.92938870)	/ POISSON_SCALE, 
	vec2(0.34495938,	0.29387760)		/ POISSON_SCALE, 
	vec2(-0.91588581,	0.45771432)		/ POISSON_SCALE, 
	vec2(-0.81544232,	-0.87912464)	/ POISSON_SCALE, 
	vec2(-0.38277543,	0.27676845)		/ POISSON_SCALE, 
	vec2(0.97484398,	0.75648379)		/ POISSON_SCALE, 
	vec2(0.44323325,	-0.97511554)	/ POISSON_SCALE, 
	vec2(0.53742981,	-0.47373420)	/ POISSON_SCALE, 
	vec2(-0.26496911,	-0.41893023)	/ POISSON_SCALE, 
	vec2(0.79197514,	0.19090188)		/ POISSON_SCALE, 
	vec2(-0.24188840,	0.99706507)		/ POISSON_SCALE, 
	vec2(-0.81409955,	0.91437590)		/ POISSON_SCALE, 
	vec2(0.19984126,	0.78641367)		/ POISSON_SCALE, 
	vec2(0.14383161,	-0.14100790) 	/ POISSON_SCALE
);

bool is_shaded(vec2 uv, float occludee_z) {
	return texture(shadow_sampler, uv).r < occludee_z;
}

float test_poisson_disc(vec2 uv, float occludee_z) {
	uv += SOFT_PENUMBRAS ? hash22(uv * 100000) * .00031 : vec2(0);
	float light = POISSON_SAMPLES;
	for (int i = 0; i < POISSON_SAMPLES; ++i) {
		light -= float(is_shaded(uv + poisson_disc[i], occludee_z));
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
	shadow_uv /= SHADOW_MAP_DIM;
	shadow_uv += offset;
	shadow_uv = clamp(shadow_uv, offset, offset + SHADOW_BOUNDARY);
	// rescale/bias occludee depth and compare to multiple occluder samples from the shadow map (i.e., PCF)
	float occludee_z = proj_pos_re_light.z * 0.5 + 0.5;
	float light = test_poisson_disc(shadow_uv, occludee_z);
	for (int i = 0; i < PCF_SAMPLES; ++i) {
		light += test_poisson_disc(shadow_uv + pcf_kernel[i], occludee_z);
	}
	return light / (PCF_SAMPLES + 1);
}

void main() {
	vec4 normal_sample		= texture(normal_sampler, var_texcoord0);
	vec4 spec_glow_sample	= texture(spec_glow_sampler, var_texcoord0);
	vec4 light_sample		= texture(light_sampler, var_texcoord0);
	vec4 vol_diff			= vec4(light_sample.rgb, 1.0);
	vec4 vol_spec			= vec4(light_sample.rgb * light_sample.a, 1.0);

	float depth			= texture(depth_buffer, var_texcoord0).r;
	float z				= linearizeDepth(depth, frustum_terms.xyz);
	vec3 var_frag_pos	= viewPosFromLinearDepth(z, var_texcoord0, frustum_corner.xyz);
	vec3 view_dir		= normalize(-var_frag_pos);
	vec3 normal			= normalize(normal_sample.xyz * 2.0 - 1.0); // rescale/bias [0, 1] -> [-1, 1]

	float shadow = 1;
	float near_edge, far_edge;
	int i;
	for (i = 0, near_edge = 0, far_edge = 0; i < NUM_PARTITIONS; ++i, near_edge = far_edge) {
		vec4 part = camera_partitions[i];
		vec2 offset = part.xy;
		float bias = part.w;
		far_edge = part.z;
		// if this fragment is beyond the far edge of this partition, skip to the next
		if (var_frag_pos.z < -far_edge) continue;
		// otherwise try to cast a shadow using this partition
		shadow = shadow_calc(vec4(var_frag_pos, 1.0), normal, mtx_lights[i], offset, bias);
		// if this fragment isn't near the far edge of this partition, or we're in the last partition, finish here
		float dist = far_edge + var_frag_pos.z;
		if (TRANSITION_RANGE == 0 || dist > TRANSITION_RANGE || i >= NUM_PARTITIONS - 1) break;
		// otherwise, blend with the next partition's shadow for a smooth transition
		vec4 next_part = camera_partitions[i + 1];
		vec2 next_offset = next_part.xy;
		float next_bias = next_part.w;
		float next_shadow = shadow_calc(vec4(var_frag_pos, 1.0), normal, mtx_lights[i + 1], next_offset, next_bias);
		shadow = mix(next_shadow, shadow, dist / TRANSITION_RANGE);
		// at this point we've tried to cast a shadow using the appropriate partition, so finish here
		break;
	}
	// fade the shadow out towards the end of the last partition
	if (i == NUM_PARTITIONS - 1 && shadow < 1) {
		float fade = smoothstep(mix(near_edge, far_edge, 0.75), far_edge, -var_frag_pos.z);
		shadow += (1.0 - shadow) * fade;
	}

	float ao = texture(ssao_sampler, var_texcoord0).r;
	float shininess = spec_glow_sample.r * 255;
	vec4 mat_diff = texture(diffuse_sampler, var_texcoord0);
	vec4 color = ambient_color * mat_diff * ao;
	float sun_spec = specular(view_dir, directional_from, normal, shininess);
	float sun_diff = diffuse(directional_from, normal);
	vec4 light_spec = clamp(sun_spec * directional_color * shadow + vol_spec, 0, 1);
	vec4 light_diff = clamp((sun_diff * directional_color * shadow + vol_diff) * ao + spec_glow_sample.g, 0, 1); // consider (ao + 1) / 2
	color += mat_diff * light_diff + light_spec; // we only support white specular highlights for now, so omit mat_spec

	float fog_intensity = smoothstep(FOG_NEAR, FOG_FAR, -var_frag_pos.z);
	color = mix(color, fog_color, fog_intensity);
	color.a = mat_diff.a;
	frag_color = normal_sample.a == 0 ? texture(diffuse_sampler, var_texcoord0) : clamp(color, 0.0, 1.0);
}
