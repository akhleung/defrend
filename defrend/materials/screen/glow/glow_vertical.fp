#version 420

in vec2 var_texcoord0;

uniform sampler2D glow_color_sampler;
uniform sampler2D orig_glow_sampler;

uniform glow_fp {
	vec4 params;
};

vec2	resolution	= textureSize(glow_color_sampler, 0);
int		radius		= int(params.x);
float	separation	= params.y;
vec2	delta		= separation * vec2(0, 1) / resolution;

layout(location = 0) out vec4 fragColor;

void main() {
	vec4 glow_sample = texture(glow_color_sampler, var_texcoord0);
	vec3 glow = glow_sample.rgb * glow_sample.a;
	for (int i = 1; i <= radius; ++i) {
		glow_sample = texture(glow_color_sampler, var_texcoord0 + delta * i);
		glow += glow_sample.rgb * glow_sample.a;
		
		glow_sample = texture(glow_color_sampler, var_texcoord0 - delta * i);
		glow += glow_sample.rgb * glow_sample.a;
	}
	glow /= (radius * 2 + 1);
	float orig_emissive = texture(orig_glow_sampler, var_texcoord0).g;
	glow *= (1 - orig_emissive / 2);
	fragColor = vec4(glow, 1);
}
