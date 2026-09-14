#version 420 core
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/dof_functions.glsl"

in vec2 var_texcoord0;

uniform sampler2D input_sampler;

uniform dof_blur_fp {
	vec4 params;
};

const float golden_angle = 2.4;

int		blur_samples			= int(params.x);
float	blur_radius				= params.y;
float	focused_coc_threshold	= params.z;

layout(location = 0) out vec4 frag_output;

void main() {

	vec2	texel_size		= 1.0 / vec2(textureSize(input_sampler, 0));

	vec4	center_value	= texture(input_sampler, var_texcoord0);
	vec3	center_color	= center_value.rgb;
	float	center_coc		= center_value.a * 2.0 - 1.0;

	vec3	color			= center_color;
	float	coc				= center_coc;

	vec2	rmax			= blur_radius * texel_size;
	vec2	rstep			= rmax / blur_samples;
	float	weight			= 1.0;
	float	scale			= 0.0;

	for (int i = 0; i < blur_samples; ++i) {
		float	rotation		= i * golden_angle;
		vec2	offset			= rstep * (i + 1);
		vec2 	sample_uv		= var_texcoord0 + vec2(sin(rotation), cos(rotation)) * offset;
		vec4 	sample_value	= texture(input_sampler, sample_uv);
		float	sample_coc		= sample_value.a * 2.0 - 1.0;

		scale = max(scale, abs(sample_coc));
	}
	rstep *= scale;

	for (int i = 0; i < blur_samples; ++i) {
		float	rotation		= i * golden_angle;
		vec2	offset			= rstep * (i + 1);
		vec2 	sample_uv		= var_texcoord0 + vec2(sin(rotation), cos(rotation)) * offset;
		vec4 	sample_value	= texture(input_sampler, sample_uv);
		vec3 	sample_color	= sample_value.rgb;
		float	sample_coc		= sample_value.a * 2.0 - 1.0;
		float	sample_weight	= abs(sample_coc);
		// if sample is focused, it should not contribute
		if (is_focused(sample_coc, focused_coc_threshold)) continue;
		// removing other kinds of samples seems to produce more aliasing, so let them all contribute
		coc = max(coc, sample_coc);
		color += sample_color * sample_weight;
		weight += sample_weight;
	}

	frag_output = vec4(color / weight, coc * 0.5 + 0.5);
}
