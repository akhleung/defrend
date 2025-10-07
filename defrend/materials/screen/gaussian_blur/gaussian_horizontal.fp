#version 420

in vec2 var_texcoord0;

uniform sampler2D color_sampler;

uniform gaussian_horizontal_fp {
	vec4 params;
};

vec2	resolution	= textureSize(color_sampler, 0);
float	separation	= params.x;
vec2	delta		= vec2(2, 0) * separation / resolution;
vec2	halfpixel	= vec2(0.5, 0) / resolution;
float	weight[5]	= float[] (0.18518, 0.15872, 0.0992, 0.04409, 0.01323);

layout(location = 0) out vec4 fragColor;

void main() {

	vec3 result = vec3(0);
	for (int i = 0; i < 5; ++i) {
		result += texture(color_sampler, var_texcoord0 + delta * i + halfpixel).rgb * weight[i];
		result += texture(color_sampler, var_texcoord0 - delta * i - halfpixel).rgb * weight[i];
	}
	fragColor = vec4(result, 1.0);
}
