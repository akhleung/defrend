#version 420

precision highp float;

in vec2 var_texcoord0;

uniform sampler2D color_sampler;

uniform gaussian_fp {
	vec4 params;
	vec4 delta;
};

vec2	resolution	= textureSize(color_sampler, 0);
float	separation	= params.x;
float	offset[3]	= float[](0.0, 1.3846153846 * separation, 3.2307692308 * separation);
float	weight[3]	= float[](0.2270270270, 0.3162162162, 0.0702702703);

layout(location = 0) out vec4 fragColor;

void main() {

	vec2 d = delta.xy / resolution;
	vec3 result = texture(color_sampler, var_texcoord0).rgb * weight[0];
	for (int i = 1; i < 3; ++i) {
		vec2 o = d * offset[i];
		result += texture(color_sampler, var_texcoord0 + o).rgb * weight[i];
		result += texture(color_sampler, var_texcoord0 - o).rgb * weight[i];
	}
	fragColor = vec4(result, 1.0);
}
