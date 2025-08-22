#version 420

in vec2 var_texcoord0;

uniform sampler2D color_sampler;
uniform sampler2D spec_glow_sampler;

uniform glow_fp {
	vec4 params;
};

vec2	resolution	= textureSize(color_sampler, 0);
int		radius		= int(params.x);
float	separation	= params.y;
vec2	delta		= separation * vec2(1, 0) / resolution;

layout(location = 0) out vec4 fragColor;

void main() {
	vec3 color = texture(color_sampler, var_texcoord0).rgb;
	float emissive = texture(spec_glow_sampler, var_texcoord0).g;
	vec3 glow = color * emissive;
	for (int i = 1; i <= radius; ++i) {
		color = texture(color_sampler, var_texcoord0 + delta * i).rgb;
		emissive = texture(spec_glow_sampler, var_texcoord0 + delta * i).g;
		glow += color * emissive;
		
		color = texture(color_sampler, var_texcoord0 - delta * i).rgb;
		emissive = texture(spec_glow_sampler, var_texcoord0 - delta * i).g;
		glow += color * emissive;
	}
	fragColor = vec4(glow / (radius * 2 + 1), 1);
}
