#version 320 es

in mediump vec2 var_texcoord0;

uniform sampler2D color_sampler;
uniform sampler2D spec_glow_sampler;

uniform bloom_fp {
	mediump vec4 params;
};

out mediump vec4 fragColor;

void main() {

	mediump vec2	resolution	= vec2(params.x, params.y);
			int		radius		= int(params.z);
	mediump float	separation	= params.w;
	mediump float	dx			= separation / resolution.x;
	mediump float	dy			= separation / resolution.y;

	mediump vec2 dirs[8] = vec2[](
		vec2(dx, 0),
		vec2(dx, dy),
		vec2(0, dy),
		vec2(-dx, dy),
		vec2(-dx, 0),
		vec2(-dx, -dy),
		vec2(0, -dy),
		vec2(dx, -dy)
	);

	fragColor = texture(color_sampler, var_texcoord0);
	mediump float emissive = texture(spec_glow_sampler, var_texcoord0).g;
	mediump vec3 glow = fragColor.rgb * emissive;
	int count = 1;
	for (int i = 0; i < 8; ++i) {
		for (int j = 1; j <= radius; ++j) {
			mediump vec2 uv = var_texcoord0 + dirs[i] * float(j);
			mediump vec3 color = texture(color_sampler, uv).rgb;
			mediump float emissive = texture(spec_glow_sampler, uv).g;
			glow += color * emissive;
			++count;
		}
	}
	glow /= float(count);
	fragColor.rgb += glow * (1.0 - emissive / 2.0);
}
