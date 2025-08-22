#version 420

in vec2 var_texcoord0;

uniform sampler2D color_sampler;

vec2	resolution	= textureSize(color_sampler, 0);
vec2	delta		= vec2(1, 0) / resolution;
float	weight[5]	= float[] (0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);

layout(location = 0) out vec4 fragColor;
layout(location = 1) out vec4 whatever;

void main() {
	vec3 result = texture(color_sampler, var_texcoord0).rgb * weight[0];
	for (int i = 1; i < 5; ++i) {
		result += texture(color_sampler, var_texcoord0 + delta * i).rgb * weight[i];
		result += texture(color_sampler, var_texcoord0 - delta * i).rgb * weight[i];
	}
	fragColor = vec4(result, 1.0);
	whatever = vec4(0);
}
