#version 420

in vec2 var_texcoord0;

uniform sampler2D color_sampler;
uniform sampler2D spec_glow_sampler;

uniform bloom_fp {
	vec4 params;
};

vec2	resolution	= textureSize(color_sampler, 0);
int		radius		= int(params.x);
float	separation	= params.y;
float	dx			= separation / resolution.x;
float	dy			= separation / resolution.y;

vec2 dirs[8] = vec2[](
	vec2(dx, 0),
	vec2(dx, dy),
	vec2(0, dy),
	vec2(-dx, dy),
	vec2(-dx, 0),
	vec2(-dx, -dy),
	vec2(0, -dy),
	vec2(dx, -dy)
);

out vec4 fragColor;

void main() {
	fragColor = texture(color_sampler, var_texcoord0);
	float emissive = texture(spec_glow_sampler, var_texcoord0).g;
	vec3 glow = fragColor.rgb * emissive;
	int count = 1;
	for (int i = 0; i < 8; ++i) {
		for (int j = 1; j <= radius; ++j) {
			vec2 uv = var_texcoord0 + dirs[i] * j;
			vec3 color = texture(color_sampler, uv).rgb;
			float emissive = texture(spec_glow_sampler, uv).g;
			glow += color * emissive;
			++count;
		}
	}
	glow /= count;
	fragColor.rgb += glow * (1 - emissive / 2);
}
