#version 420 core
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/lighting_functions.glsl"

#define PI 3.141592654
#define X vec3(1, 0, 0)
#define Y vec3(0, 1, 0)

in vec3 var_center;
in vec3 var_center_w;
in vec3 var_color;
in float var_radius;
in float var_attn;
#ifdef EDITOR
in vec3 var_normal;
#endif

uniform sampler2D depth_buffer;
uniform sampler2D normal_sampler;
uniform samplerCube shadow_map;

uniform point_light_fp {
	mat4 mtx_lights[6]; // light projection * light views (so they require a position in world space)
    vec4 frustum_corner;
    vec4 frustum_terms;
	mat4 mtx_view_inv;
	vec4 shadow_params1; // x: near bias, y: far bias, z: soft penumbras, w: pcf samples
	vec4 shadow_params2; // x: poisson samples, y: poisson scale, z: hash factor, w: hash scale
	vec4 texel_size; // x: texel size
};

float	near_bias		= shadow_params1.x;
float	far_bias		= shadow_params1.y;
bool	SOFT_PENUMBRAS	= bool(shadow_params1.z);
int		PCF_SAMPLES		= int(shadow_params1.w);
int		POISSON_SAMPLES	= int(shadow_params2.x);
float	POISSON_SCALE	= shadow_params2.y;
float	HASH_FACTOR		= shadow_params2.z;
float	HASH_SCALE		= shadow_params2.w;

vec2 pcf_kernel[8] = vec2[](
	vec2(-1, 0)		* texel_size.x,
	vec2(1, 0)		* texel_size.x,
	vec2(0, -1)		* texel_size.x,
	vec2(0, 1)		* texel_size.x,
	vec2(-1, -1)	* texel_size.x,
	vec2(1, 1)		* texel_size.x,
	vec2(1, -1)		* texel_size.x,
	vec2(-1, 1)		* texel_size.x
);

vec2 poisson_disc[16] = vec2[]( 
	vec2(-0.94201624,	-0.39906216)	* POISSON_SCALE * texel_size.x,
	vec2(0.94558609,	-0.76890725)	* POISSON_SCALE * texel_size.x,
	vec2(-0.094184101,	-0.92938870)	* POISSON_SCALE * texel_size.x,
	vec2(0.34495938,	0.29387760)		* POISSON_SCALE * texel_size.x,
	vec2(-0.91588581,	0.45771432)		* POISSON_SCALE * texel_size.x,
	vec2(-0.81544232,	-0.87912464)	* POISSON_SCALE * texel_size.x,
	vec2(-0.38277543,	0.27676845)		* POISSON_SCALE * texel_size.x,
	vec2(0.97484398,	0.75648379)		* POISSON_SCALE * texel_size.x,
	vec2(0.44323325,	-0.97511554)	* POISSON_SCALE * texel_size.x,
	vec2(0.53742981,	-0.47373420)	* POISSON_SCALE * texel_size.x,
	vec2(-0.26496911,	-0.41893023)	* POISSON_SCALE * texel_size.x,
	vec2(0.79197514,	0.19090188)		* POISSON_SCALE * texel_size.x,
	vec2(-0.24188840,	0.99706507)		* POISSON_SCALE * texel_size.x,
	vec2(-0.81409955,	0.91437590)		* POISSON_SCALE * texel_size.x,
	vec2(0.19984126,	0.78641367)		* POISSON_SCALE * texel_size.x,
	vec2(0.14383161,	-0.14100790) 	* POISSON_SCALE * texel_size.x
);

layout(location = 0) out vec4 light_out;

// bool is_shaded(vec2 uv, float occludee_z) {
// 	return texture(shadow_map, uv).r < occludee_z;
// }

// float test_poisson_disc(vec2 uv, float occludee_z) {
// 	float light = POISSON_SAMPLES + 1;
// 	light -= float(is_shaded(uv, occludee_z));
// 	if (SOFT_PENUMBRAS) uv += hash22(uv * HASH_FACTOR) * HASH_SCALE * texel_size.x;
// 	for (int i = 0; i < POISSON_SAMPLES; ++i) {
// 		light -= float(is_shaded(uv + poisson_disc[i], occludee_z));
// 	}
// 	return light / (POISSON_SAMPLES + 1);
// }

bool is_pos(float x) {
	return sign(x) > 0;
}

void main() {
	ivec2 frag_coord = ivec2(gl_FragCoord.xy);
	float depth = texelFetch(depth_buffer, frag_coord, 0).r;
	float z = linearizeDepth(depth, frustum_terms.xyz);
	vec2 screen_uv = gl_FragCoord.xy / textureSize(depth_buffer, 0);
	vec3 geom_pos = viewPosFromLinearDepth(z, screen_uv, frustum_corner.xyz);
	vec4 normal_sample = texelFetch(normal_sampler, frag_coord, 0);
	float shininess = normal_sample.a * 255;
	vec3 to_light = var_center - geom_pos;
	float d = length(to_light);
	if (d > var_radius) discard;

	// Determine which cubemap face will be sampled -- we need to do this to determine the correct matrix for
	// transforming the g-buffer fragment into light space.
	// Given a fragment position relative to the center of the light, the component with the highest magnitude
	// should indicate the relevant cubemap face.
	vec3 normal = normalize(normal_sample.xyz * 2.0 - 1.0);
	float bias = mix(near_bias, far_bias, d / var_radius);
	vec4 geom_pos_w = mtx_view_inv * vec4(geom_pos + normal * bias, 1.0);
	vec3 geom_pos_l = geom_pos_w.xyz - var_center_w;
	float mag_x = abs(geom_pos_l.x), mag_y = abs(geom_pos_l.y), mag_z = abs(geom_pos_l.z);
	int cube_face = 0;
	if (mag_x > mag_y && mag_x > mag_z) {
		cube_face = is_pos(geom_pos_l.x) ? 0 : 1;
	} else if (mag_y > mag_x && mag_y > mag_z) {
		cube_face = is_pos(geom_pos_l.y) ? 2 : 3;
	} else {
		cube_face = is_pos(geom_pos_l.z) ? 4 : 5;
	}
	mat4 mtx_light = mtx_lights[cube_face];

	vec4 geom_pos_s = mtx_light * geom_pos_w;
	geom_pos_s /= geom_pos_s.w;
	float occludee_z = geom_pos_s.z * 0.5 + 0.5;

	float light = texture(shadow_map, geom_pos_l).r < occludee_z ? 0 : 1;

	// sample the shadow map, compare depth of sample to depth of fragment, etc
	// float light = test_poisson_disc(shadow_uv, occludee_z);
	// for (int i = 0; i < PCF_SAMPLES; ++i) {
	// 	light += test_poisson_disc(shadow_uv + pcf_kernel[i] + poisson_disc[i], occludee_z);
	// }
	// light /= (PCF_SAMPLES + 1);

	// do the actual lighting calculations
	vec3 to_view = -geom_pos;
	vec3 to_light_normalized = normalize(to_light);
	float diff = diffuse(to_light_normalized, normal);
	float spec = specular(normalize(to_view), to_light_normalized, normal, shininess);
	float attn = attn_inv_pow(d, var_radius, var_attn);
	light_out = vec4(var_color * diff * attn, spec * attn) * light;

	#ifdef EDITOR // visualization for viewing point light volumes in the editor
	vec3 lat_normal = normalize(vec3(var_normal.x, 0, var_normal.z));
	vec2 dots = abs(vec2(dot(lat_normal, X), dot(var_normal, Y)));
	vec2 rads = acos(dots);
	vec2 degs = floor(rads * 180 / PI);
	vec2 rems = fract(degs / 24);
	if (rems.x == 0 || rems.y == 0) {
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
