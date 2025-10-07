#version 420

in vec2 var_texcoord0;

uniform sampler2D glow_color_sampler; // blur_source: 1/2 res
uniform sampler2D orig_glow_sampler; // g_buffer:color2: full res

uniform glow_fp {
	vec4 params;
};

vec2	resolution	= textureSize(glow_color_sampler, 0);
float	separation	= params.x;
vec2	delta		= vec2(0, 2) * separation / resolution;
vec2	halfpixel	= vec2(0, 0.5) / resolution;
float	weight[5]	= float[] (0.18518, 0.15872, 0.0992, 0.04409, 0.01323);

layout(location = 0) out vec4 fragColor; // blur_target: 1/2 res

void main() {
	vec4 glow_sample;
	vec3 glow = vec3(0);
	for (int i = 0; i < 5; ++i) {
		glow_sample = texture(glow_color_sampler, var_texcoord0 + delta * i + halfpixel);
		glow += glow_sample.rgb * weight[i];
		
		glow_sample = texture(glow_color_sampler, var_texcoord0 - delta * i - halfpixel);
		glow += glow_sample.rgb * weight[i];
	}
	fragColor = vec4(glow, 1);
}
