#version 420

in vec2 var_texcoord0;

uniform sampler2D color_sampler;
uniform sampler2D spec_glow_sampler;

uniform glow_fp {
	vec4 params;
};

vec2	resolution	= textureSize(color_sampler, 0);
float	separation	= params.x;
vec2	delta		= vec2(2, 0) * separation / resolution;
vec2	halfpixel	= vec2(0.5, 0) / resolution;
float	weight[5]	= float[] (0.18518, 0.15872, 0.0992, 0.04409, 0.01323);

layout(location = 0) out vec4 fragColor;

void main() {
	vec3 color;
	float emissive;
	vec3 glow = vec3(0);
	for (int i = 0; i < 5; ++i) {
		vec2 xy_r = var_texcoord0 + delta * i + halfpixel;
		color = texture(color_sampler, xy_r).rgb;
		emissive = texture(spec_glow_sampler, xy_r).g;
		glow += color * emissive * weight[i];
		
		vec2 xy_l = var_texcoord0 - delta * i - halfpixel;
		color = texture(color_sampler, xy_l).rgb;
		emissive = texture(spec_glow_sampler, xy_l).g;
		glow += color * emissive * weight[i];
	}
	fragColor = vec4(glow, 1);
}
