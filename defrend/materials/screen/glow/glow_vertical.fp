#version 420

in vec2 var_texcoord0;

uniform sampler2D glow_color_sampler; // blur_source: 1/2 res
uniform sampler2D orig_glow_sampler; // g_buffer:color2: full res

uniform glow_fp {
	vec4 params;
};

vec2	resolution	= textureSize(glow_color_sampler, 0);
int		radius		= int(params.x);
float	separation	= params.y;
vec2	delta		= vec2(0, 2);
float	weight[5]	= float[] (0.18518, 0.15872, 0.0992, 0.04409, 0.01323);

layout(location = 0) out vec4 fragColor; // blur_target: 1/2 res

void main() {
	vec4 glow_sample;
	vec3 glow = vec3(0);
	for (int i = 0; i < radius; ++i) {
		vec2 xy_u = ((gl_FragCoord.xy + delta * i * separation) + 0.5) / resolution;
		glow_sample = texture(glow_color_sampler, xy_u);
		glow += glow_sample.rgb * weight[i];
		
		vec2 xy_d = ((gl_FragCoord.xy - delta * i * separation) - 0.5) / resolution;
		glow_sample = texture(glow_color_sampler, xy_d);
		glow += glow_sample.rgb * weight[i];
	}
	// float orig_emissive = texture(orig_glow_sampler, var_texcoord0).g;
	// glow *= (1 - orig_emissive / 2);
	fragColor = vec4(glow, 1);
}
