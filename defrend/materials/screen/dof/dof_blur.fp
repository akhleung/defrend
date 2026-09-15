#version 420 core
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/lighting_functions.glsl"

in vec2 var_texcoord0;

uniform sampler2D input_sampler;
// uniform sampler2D depth_buffer;

uniform dof_blur_fp {
	vec4 params;
	vec4 frustum_terms;
	vec4 frustum_corner;
};

vec2 hex_kernel[6] = vec2[](
				vec2(0.0, 1.0),
	vec2(-0.866, 0.5),		vec2(0.866, 0.5),
	vec2(-0.866, -0.5),		vec2(0.866, -0.5),
				vec2(0.0, -1.0)
);

const float golden_angle	= 2.4;

int blur_samples = int(params.x);
float blur_scale = params.y;

layout(location = 0) out vec4 blurred_near;
layout(location = 1) out vec4 blurred_far;

void main() {

	vec2	texel_size		= 1.0 / vec2(textureSize(input_sampler, 0));

	vec4	center_value	= texture(input_sampler, var_texcoord0);
	vec3	center_color	= center_value.rgb;
	float	center_coc		= center_value.a * 2.0 - 1.0;
	// float	center_z		= linearizeDepth(texture(depth_buffer, var_texcoord0).r, frustum_terms.xyz);
	// float	center_zn		= center_z / frustum_corner.z;
	vec2	rstep			= blur_scale * abs(center_coc) * texel_size;

	vec3	color			= center_color;
	float	coc				= center_coc;
	int		contributors	= 1;

	vec4	acc_near		= vec4(0);
	vec4	acc_far			= vec4(0);

	for (int i = 0; i < blur_samples; ++i) {
		float	rotation		= i * golden_angle;
		vec2 	sample_uv		= var_texcoord0 + vec2(sin(rotation), cos(rotation)) * rstep * (i + 1);
		vec4 	sample_value	= texture(input_sampler, sample_uv);
		vec3 	sample_color	= sample_value.rgb;
		float	sample_coc		= sample_value.a * 2.0 - 1.0;

		float	weight_far		= max(0, -sample_coc);
		float	weight_near		= sample_coc > center_coc ? 0 : max(0, sample_coc);

		acc_far		+= vec4(sample_color * weight_far, weight_far);
		acc_near	+= vec4(sample_color * weight_near, weight_near);

		// float	sample_z		= linearizeDepth(texture(depth_buffer, sample_uv).r, frustum_terms.xyz);
		// float	sample_zn		= sample_z / frustum_corner.z;
		// color += sample_color;
		// ++contributors;
		// coc = min(coc, sample_coc);
	}

	blurred_far		= vec4(acc_far.rgb / max(acc_far.a, 0.0001), clamp(acc_far.a, 0, 1));
	blurred_near	= vec4(acc_near.rgb / max(acc_near.a, 0.0001), clamp(acc_near.a, 0, 1));

	// for (int i = 0; i < blur_samples; ++i) {
	// 	for (int j = 0; j < 6; ++j) {
	// 		vec2	sample_uv		= var_texcoord0 + hex_kernel[j] * rstep * i;
	// 		vec4 	sample_value	= texture(input_sampler, sample_uv);
	// 		vec3 	sample_color	= sample_value.rgb;
	// 		float	sample_coc		= sample_value.a * 2.0 - 1.0;
	// 		color += sample_color;
	// 		++contributors;
	// 	}
	// }

	// frag_color = vec4(color / contributors, abs(coc));
}
