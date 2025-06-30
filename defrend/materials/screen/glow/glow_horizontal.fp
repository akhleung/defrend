#version 320 es

in mediump vec2 var_texcoord0;

uniform sampler2D color_sampler;
uniform sampler2D spec_glow_sampler;

uniform glow_fp {
	mediump vec4 params;
};

layout(location = 0) out mediump vec4 fragColor;

void main() {

	mediump vec2	resolution	= vec2(params.x, params.y);
			int		radius		= int(params.z);
	mediump float	separation	= params.w;
	mediump vec2	delta		= separation * vec2(1, 0) / resolution;

	mediump vec3 color = texture(color_sampler, var_texcoord0).rgb;
	mediump float emissive = texture(spec_glow_sampler, var_texcoord0).g;
	mediump vec3 glow = color * emissive;
	for (int i = 1; i <= radius; ++i) {
		color = texture(color_sampler, var_texcoord0 + delta * float(i)).rgb;
		emissive = texture(spec_glow_sampler, var_texcoord0 + delta * float(i)).g;
		glow += color * emissive;
		
		color = texture(color_sampler, var_texcoord0 - delta * float(i)).rgb;
		emissive = texture(spec_glow_sampler, var_texcoord0 - delta * float(i)).g;
		glow += color * emissive;
	}
	fragColor = vec4(glow / (float(radius) * 2.0 + 1.0), 1.0);
}
