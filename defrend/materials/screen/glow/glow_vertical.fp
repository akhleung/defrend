#version 320 es

in mediump vec2 var_texcoord0;

uniform sampler2D color_sampler;
uniform sampler2D glow_color_sampler;
uniform sampler2D orig_glow_sampler;

uniform glow_fp {
	mediump vec4 params;
};

layout(location = 0) out mediump vec4 fragColor;

void main() {

	mediump vec2	resolution	= vec2(params.x, params.y);
			int		radius		= int(params.z);
	mediump float	separation	= params.w;
	mediump vec2	delta		= separation * vec2(0, 1) / resolution;

	mediump vec4 glow_sample = texture(glow_color_sampler, var_texcoord0);
	mediump vec3 glow = glow_sample.rgb * glow_sample.a;
	for (int i = 1; i <= radius; ++i) {
		glow_sample = texture(glow_color_sampler, var_texcoord0 + delta * float(i));
		glow += glow_sample.rgb * glow_sample.a;
		
		glow_sample = texture(glow_color_sampler, var_texcoord0 - delta * float(i));
		glow += glow_sample.rgb * glow_sample.a;
	}
	glow /= (float(radius) * 2.0 + 1.0);
	mediump float orig_emissive = texture(orig_glow_sampler, var_texcoord0).g;
	fragColor = texture(color_sampler, var_texcoord0);
	fragColor.rgb += glow * (1.0 - orig_emissive / 2.0);
}
