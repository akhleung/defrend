#version 420 core
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/lighting_functions.glsl"

#define PI 3.141592654

in vec3 var_source;
in vec3 var_light_dir;
in vec3 var_color;
in float var_spread;
in float var_range;
in float var_start;
in float var_coverage;
in float var_range_attn;
in float var_spread_attn;
#ifdef EDITOR
in vec3 var_frag_pos;
in vec3 var_edge_pos;
in vec3 var_lat_norm;
in vec3 var_lat_axis;
in float var_pcnt_start;
#endif

uniform sampler2D depth_buffer;
uniform sampler2D normal_sampler;
uniform sampler2D shadow_map;

uniform spot_light_fp {
	mat4 mtx_view_inv;
	mat4 mtx_light; // (light's proj mtx) * (light's view mtx)
	vec4 shadow_params1; // x: near bias, y: far bias, z: soft penumbras, w: pcf samples
	vec4 shadow_params2; // x: poisson samples, y: poisson scale, z: hash factor, w: hash scale
	vec4 texel_size;
    vec4 frustum_corner;
    vec4 frustum_terms;
};

float near_bias		= shadow_params1.x;
float far_bias		= shadow_params1.y;
bool SOFT_PENUMBRAS	= bool(shadow_params1.z);
int PCF_SAMPLES		= int(shadow_params1.w);
int POISSON_SAMPLES	= int(shadow_params2.x);
float POISSON_SCALE	= shadow_params2.y;
float HASH_FACTOR	= shadow_params2.z;
float HASH_SCALE	= shadow_params2.w;

vec2 pcf_kernel[8] = vec2[](
	vec2(-1, 0)		* texel_size.xy,
	vec2(1, 0)		* texel_size.xy,
	vec2(0, -1)		* texel_size.xy,
	vec2(0, 1)		* texel_size.xy,
	vec2(-1, -1)	* texel_size.xy,
	vec2(1, 1)		* texel_size.xy,
	vec2(1, -1)		* texel_size.xy,
	vec2(-1, 1)		* texel_size.xy
);

vec2 poisson_disc[16] = vec2[]( 
	vec2(-0.94201624,	-0.39906216)	* POISSON_SCALE, 
	vec2(0.94558609,	-0.76890725)	* POISSON_SCALE, 
	vec2(-0.094184101,	-0.92938870)	* POISSON_SCALE, 
	vec2(0.34495938,	0.29387760)		* POISSON_SCALE, 
	vec2(-0.91588581,	0.45771432)		* POISSON_SCALE, 
	vec2(-0.81544232,	-0.87912464)	* POISSON_SCALE, 
	vec2(-0.38277543,	0.27676845)		* POISSON_SCALE, 
	vec2(0.97484398,	0.75648379)		* POISSON_SCALE, 
	vec2(0.44323325,	-0.97511554)	* POISSON_SCALE, 
	vec2(0.53742981,	-0.47373420)	* POISSON_SCALE, 
	vec2(-0.26496911,	-0.41893023)	* POISSON_SCALE, 
	vec2(0.79197514,	0.19090188)		* POISSON_SCALE, 
	vec2(-0.24188840,	0.99706507)		* POISSON_SCALE, 
	vec2(-0.81409955,	0.91437590)		* POISSON_SCALE, 
	vec2(0.19984126,	0.78641367)		* POISSON_SCALE, 
	vec2(0.14383161,	-0.14100790) 	* POISSON_SCALE
);

bool is_shaded(vec2 uv, float occludee_z) {
	return texture(shadow_map, uv).r < occludee_z;
}

float test_poisson_disc(vec2 uv, float occludee_z) {
	float light = POISSON_SAMPLES + 1;
	light -= float(is_shaded(uv, occludee_z));
	if (SOFT_PENUMBRAS) uv += hash22(uv * HASH_FACTOR) * HASH_SCALE;
	for (int i = 0; i < POISSON_SAMPLES; ++i) {
		light -= float(is_shaded(uv + poisson_disc[i], occludee_z));
	}
	return light / (POISSON_SAMPLES + 1);
}

layout(location = 0) out vec4 light_out;

void main() {

	vec2 texcoord = gl_FragCoord.xy / textureSize(depth_buffer, 0);
    float depth = texture(depth_buffer, texcoord).r;
	float z = linearizeDepth(depth, frustum_terms.xyz);
	vec3 geom_pos = viewPosFromLinearDepth(z, texcoord, frustum_corner.xyz);
	vec4 normal_sample = texture(normal_sampler, texcoord);
	float shininess = normal_sample.a * 255;

	vec3 to_light = var_source - geom_pos;
	vec3 to_light_normalized = normalize(to_light);
	float d = length(to_light);
	float a = dot(normalize(geom_pos - var_source), var_light_dir);
	if (a < var_spread || d > var_range || d < var_start) discard;

	float d_from_start = d - var_start;
	vec3 normal = normalize(normal_sample.xyz * 2.0 - 1.0);
	float bias = mix(near_bias, far_bias, d_from_start / (var_coverage));
	vec4 geom_pos_s = mtx_light * mtx_view_inv * vec4(geom_pos + normal * bias, 1.0);
	geom_pos_s /= geom_pos_s.w;
	vec2 shadow_uv = geom_pos_s.xy * 0.5 + 0.5;
	shadow_uv = clamp(shadow_uv, 0, 1);

	float occludee_z = geom_pos_s.z * 0.5 + 0.5;
	float light = test_poisson_disc(shadow_uv, occludee_z);
	for (int i = 0; i < PCF_SAMPLES; ++i) {
		light += test_poisson_disc(shadow_uv + pcf_kernel[i] + poisson_disc[i], occludee_z);
	}
	light /= (PCF_SAMPLES + 1);

	vec3 to_view = -geom_pos;
	float diff = diffuse(to_light_normalized, normal);
	float spec = specular(normalize(to_view), to_light_normalized, normal, shininess);
	float attn_range = attn_inv_pow(d_from_start, var_coverage, var_range_attn);
	float attn_spread = attn_inv_pow(1 - a, 1 - var_spread, var_spread_attn);
	float attn = attn_range * attn_spread;
	light_out = vec4(var_color * diff * attn, spec * attn) * light;

	#ifdef EDITOR // visualization for viewing spot light volumes in the editor
	float frag_dist = distance(var_source, var_frag_pos);
	float edge_dist = distance(var_source, var_edge_pos);
	float pcnt_dist = floor(100 * (frag_dist / edge_dist));
	float step_size = 10;
	float rem = fract(pcnt_dist / step_size);

	float dotl = dot(normalize(var_lat_norm - vec3(0, var_lat_norm.y, 0)), var_lat_axis);
	float radl = acos(dotl);
	float degl = floor(radl * 180 / PI);
	float reml = fract(degl / 36);
	if (pcnt_dist < var_pcnt_start) {
		discard;
	} else if (abs(var_pcnt_start - pcnt_dist) == 0) {
		light_out = vec4(var_color, 1.0);
	} else if (rem == 0 || pcnt_dist == 100 || reml == 0) {
		light_out = vec4(var_color, 1.0);
	} else if (int(gl_FragCoord.y) % 4 == 0 && int(gl_FragCoord.x) % 2 == 0) {
		light_out = vec4(var_color, 1.0);
	} else if (int(gl_FragCoord.y) % 4 == 0) {
		discard;
	} else if (int(gl_FragCoord.y) % 2 == 0 && int(gl_FragCoord.x) % 2 != 0) {
		light_out = vec4(var_color, 1.0);
	} else {
		discard;
	}
	#endif
}
