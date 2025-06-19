#version 420

in vec2 var_texcoord0;

uniform sampler2D color_sampler;
uniform sampler2D spec_glow_sampler;

uniform glow_fp {
	vec4 params;
};

vec2	resolution	= vec2(params.x, params.y);
vec2	delta		= vec2(1, 0) / resolution;
float	weight[5]	= float[] (0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);

out vec4 fragColor;

void main() {
	vec3 result = vec3(0);
	vec3 color = texture(color_sampler, var_texcoord0).rgb;

	float emissive = texture(spec_glow_sampler, var_texcoord0).g;
	result += color * emissive /* * weight[0] */;
	float total_emissive = (1 - emissive);
	for (int i = 1; i < 5; ++i) {
		color = texture(color_sampler, var_texcoord0 + delta * i).rgb;
		emissive = texture(spec_glow_sampler, var_texcoord0 + delta * i).g;
		result += color * emissive /* * weight[i] */;
		total_emissive += (1 - emissive);
		
		color = texture(color_sampler, var_texcoord0 - delta * i).rgb;
		emissive = texture(spec_glow_sampler, var_texcoord0 - delta * i).g;
		result += color * emissive /* * weight[i] */;
		total_emissive += (1 - emissive);
	}
	fragColor = vec4(result / 9, total_emissive / 9);
}
