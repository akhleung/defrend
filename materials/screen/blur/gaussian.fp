#version 420

in vec2 var_texcoord0;

uniform sampler2D color_sampler;

uniform box_blur_fp {
	vec4 params;
};

vec2	resolution	= vec2(params.x, params.y);
vec2	delta		= vec2(params.z, params.w) / resolution;
float	weight[5]	= float[] (0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);

out vec4 fragColor;

void main() {
	vec3 result = texture(color_sampler, var_texcoord0).rgb * weight[0];
	for (int i = 1; i < 5; ++i) {
		result += texture(color_sampler, var_texcoord0 + delta * i).rgb * weight[i];
		result += texture(color_sampler, var_texcoord0 - delta * i).rgb * weight[i];
	}
	fragColor = vec4(result, 1.0);
}
