#version 420 core
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/lighting_functions.glsl"

in vec2 var_texcoord0;

uniform sampler2D input_sampler;

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

layout(location = 0) out vec4 frag_output;

void main() {

	vec2	texel_size		= 1.0 / vec2(textureSize(input_sampler, 0));

	vec4	center_value	= texture(input_sampler, var_texcoord0);
	vec3	center_color	= center_value.rgb;
	float	center_coc		= center_value.a * 2.0 - 1.0;
	vec2	rstep			= blur_scale * abs(center_coc) * texel_size;
	rstep = blur_scale * texel_size;

	vec3	color			= center_color;
	float	coc				= center_coc;
	int		contributors	= 1;

	for (int i = 0; i < blur_samples; ++i) {
		float	rotation		= i * golden_angle;
		vec2 	sample_uv		= var_texcoord0 + vec2(sin(rotation), cos(rotation)) * rstep * (i + 1);
		vec4 	sample_value	= texture(input_sampler, sample_uv);
		vec3 	sample_color	= sample_value.rgb;
		float	sample_coc		= sample_value.a * 2.0 - 1.0;
		color += sample_color;
		++contributors;
		coc = max(coc, sample_coc);
	}

	// frag_output = vec4(weight * 0.5 + 0.5);

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

	frag_output = vec4(color / contributors, coc * 0.5 + 0.5);
}
