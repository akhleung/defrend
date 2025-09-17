#version 420

in vec2 var_texcoord0;

uniform sampler2D color_sampler;

vec2	resolution	= textureSize(color_sampler, 0);
vec2	delta		= vec2(0, 2);
float	weight[5]	= float[] (0.18518, 0.15872, 0.0992, 0.04409, 0.01323);

layout(location = 0) out vec4 fragColor;

void main() {

	vec3 result = vec3(0);
	for (int i = 0; i < 5; ++i) {
		// Sample between pairs of pixels and use linear filtering in the material so that the hardware blends
		// the samples. Allows us to increase the blur radius without increasing the number of samples or
		// sacrificing quality.
		vec2 xy_u = gl_FragCoord.xy + delta * i + 0.5;
		vec2 xy_d = gl_FragCoord.xy - delta * i - 0.5;
		result += texture(color_sampler, xy_u / resolution).rgb * weight[i];
		result += texture(color_sampler, xy_d / resolution).rgb * weight[i];
	}
	fragColor = vec4(result, 1.0);
}
