#version 420 core
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/lighting_functions.glsl"

#define MAX_SAMPLES 32

in vec2 var_texcoord0;

uniform sampler2D depth_buffer;
uniform sampler2D normal_sampler;

uniform ssao_fp {
	mat4 mtx_view;
	mat4 mtx_view_inv;
	mat4 mtx_proj;
	vec4 params1;
	vec4 params2;
	vec4 kernel[MAX_SAMPLES];
	vec4 noise[MAX_SAMPLES];
	vec4 frustum_corner;
	vec4 frustum_terms;
};

int		samples			= int(params1.x);
float	intensity		= params1.y;
float	bias_angle		= params1.z;
float	bias_dist		= params1.w;
float	min_distance	= params2.x;
float	max_distance	= params2.y;
float	attn			= params2.z;
float	radius			= params2.w;

const float goldenAngle = 2.4;

out vec4 frag_color;

void main() {

	float	depth		= texture(depth_buffer, var_texcoord0).r;
	float	z			= linearizeDepth(depth, frustum_terms.xyz);
	vec3	origin_v	= viewPosFromLinearDepth(z, var_texcoord0, frustum_corner.xyz);
	vec3	origin_w	= (mtx_view_inv * vec4(origin_v, 1.0)).xyz;
  	vec3	normal_v	= texture(normal_sampler, var_texcoord0).xyz * 2.0 - 1.0;
	vec3	normal_w	= normalize(mat3(mtx_view_inv) * normal_v);
	vec3	noise_vec	= noise[int(abs(dot(ceil(origin_w), vec3(7, 11, 13)))) % samples].xyz;

	float occluders = 0;
	for (int i = 0; i < samples; ++i) {
		vec3 displacement = reflect(kernel[i].xyz, noise_vec);
		float angle = dot(normalize(displacement), normal_w);
		if (angle < 0) {
			displacement = -displacement;
		} else if (angle < bias_angle) {
			displacement = (displacement + normal_w) * 0.5;
		}
		// displacement = dot(displacement, normal_w) < 0 ? reflect(displacement, normal_w) * radius : displacement;
		// displacement = (dot(displacement, normal_w) < 0 ? -displacement : displacement) * radius;
		// vec3 displacement = (dot(kernel[i].xyz, normal_w) < 0 ? -1 : 1) * kernel[i].xyz * radius;
		vec3 sample_w = origin_w + displacement; // sample position in world space
		vec4 sample_v = mtx_view * vec4(sample_w, 1.0); // sample position in view space
		vec4 sample_proj = mtx_proj * sample_v; // sample position in clip space
		vec2 sample_uv = ((sample_proj / sample_proj.w) * 0.5 + 0.5).xy; // perspective divide; scale and bias [-1, 1] -> [0, 1]
		float occluder_z = linearizeDepth(texture(depth_buffer, sample_uv).r, frustum_terms.xyz); // occluder depth in view space
		vec3 occluder_v = viewPosFromLinearDepth(occluder_z, sample_uv, frustum_corner.xyz); // occluder position in view space
		float dist = distance(origin_v, occluder_v);
		occluders += dist > max_distance || sample_v.z > occluder_z ? 0 : 1;
	}

	frag_color = depth == 1.0 ? vec4(1.0) : vec4(1.0 - occluders / samples);
}
