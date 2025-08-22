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

out vec4 fragColor;

void main() {
	vec3 glow = vec3(0);
	int count = 0;
	for (int i = -radius; i <= radius; ++i) {
		for (int j = -radius; j <= radius; ++j) {
			vec2 uv = (gl_FragCoord.xy + (vec2(i, j) * separation)) / resolution;
			vec3 color = texture(color_sampler, uv).rgb;
			float emissive = texture(spec_glow_sampler, uv).g;
			vec3 contribution = color * emissive;
			glow += contribution;
			++count;
		}
	}
	glow /= count;
	fragColor = texture(color_sampler, var_texcoord0);
	float emissive = texture(spec_glow_sampler, var_texcoord0).g;
	fragColor.rgb += glow * (emissive > 0 ? 0 : 1);
}
