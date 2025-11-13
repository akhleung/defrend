#version 420
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/lighting_functions.glsl"

precision highp float;

in vec2 var_texcoord0;

uniform sampler2D color_sampler;
uniform sampler2D depth_buffer;
uniform sampler2D normal_sampler;

uniform ssao_blur_horizontal_fp {
	vec4 params;
	vec4 frustum_terms;
};

float	radius = params.x;
float	depth_threshold = params.y;
float	normal_threshold = params.z;
vec2	resolution	= textureSize(color_sampler, 0);
vec2	delta		= vec2(0, 1) / resolution;

layout(location = 0) out vec4 fragColor;

void main() {

	float result = texture(color_sampler, var_texcoord0).r;
	float depth = texture(depth_buffer, var_texcoord0).r;
	float z = linearizeDepth(depth, frustum_terms.xyz);
	vec3  normal = texture(normal_sampler, var_texcoord0).xyz * 2.0 - 1.0;
	float total_weight = 1;

	for (int i = 1; i < radius; ++i) {
		vec2 d_i = delta * i;

		vec2 offset_l = var_texcoord0 - d_i;
		float depth_l = texture(depth_buffer, var_texcoord0 - d_i).r;
		float z_l = linearizeDepth(depth_l, frustum_terms.xyz);
		vec3 normal_l = texture(normal_sampler, var_texcoord0 - d_i).xyz * 2.0 - 1.0;
		float sample_l = texture(color_sampler, var_texcoord0 - d_i).r;
		float weight_l = step(abs(z - z_l), depth_threshold) * step(normal_threshold, dot(normal, normal_l));
		result += sample_l * weight_l;
		total_weight += weight_l;

		vec2 offset_r = var_texcoord0 + d_i;
		float depth_r = texture(depth_buffer, var_texcoord0 + d_i).r;
		float z_r = linearizeDepth(depth_r, frustum_terms.xyz);
		vec3 normal_r = texture(normal_sampler, var_texcoord0 + d_i).xyz * 2.0 - 1.0;
		float sample_r = texture(color_sampler, var_texcoord0 + d_i).r;
		float weight_r = step(abs(z - z_r), depth_threshold) * step(normal_threshold, dot(normal, normal_r));
		result += sample_r * weight_r;
		total_weight += weight_r;
	}
	result /= total_weight;
	fragColor = vec4(vec3(result), 1.0);
}
