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
vec2	delta		= vec2(2, 0);
float	weight[5]	= float[] (0.18518, 0.15872, 0.0992, 0.04409, 0.01323);

layout(location = 0) out vec4 fragColor;

void main() {
	vec3 color;
	float emissive;
	vec3 glow = vec3(0);
	for (int i = 0; i < radius; ++i) {
		vec2 xy_r = ((gl_FragCoord.xy + delta * i * separation) + 0.5) / resolution;
		color = texture(color_sampler, xy_r).rgb;
		emissive = texture(spec_glow_sampler, xy_r).g;
		glow += color * emissive * weight[i];
		
		vec2 xy_l = ((gl_FragCoord.xy - delta * i * separation) - 0.5) / resolution;
		color = texture(color_sampler, xy_l).rgb;
		emissive = texture(spec_glow_sampler, xy_l).g;
		glow += color * emissive * weight[i];
	}
	fragColor = vec4(glow, 1);
}
