#version 420

precision highp float;

in vec2 var_texcoord0;

uniform sampler2D color_sampler;

uniform gaussian_vertical_fp {
	vec4 params;
};

vec2	resolution	= textureSize(color_sampler, 0);
float	separation	= params.x;
vec2	delta		= vec2(0, 2) * separation / resolution;
// vec2	halfpixel	= vec2(0, 0.5) / resolution;
// float	weight[5]	= float[] (0.18518, 0.15872, 0.0992, 0.04409, 0.01323);
float offset[3] = float[](0.0, 1.3846153846 / resolution.y, 3.2307692308 / resolution.y);
float weight[3] = float[](0.2270270270, 0.3162162162, 0.0702702703);

layout(location = 0) out vec4 fragColor;

void main() {

	vec3 result = texture(color_sampler, var_texcoord0).rgb * weight[0];
	for (int i = 1; i < 3; ++i) {
		vec2 o = vec2(0, offset[i]);
		result += texture(color_sampler, var_texcoord0 + o).rgb * weight[i];
		result += texture(color_sampler, var_texcoord0 - o).rgb * weight[i];
	}
	fragColor = vec4(result, 1.0);
}
