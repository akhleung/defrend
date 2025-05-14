#version 420

in vec2 var_texcoord0;

uniform sampler2D color_sampler;

uniform box_blur_fp {
	vec4 params;
};

vec2 resolution = vec2(params.x, params.y);
int radius = int(params.z);
float separation = params.w;

out vec4 fragColor;

void main() {
	fragColor = texture(color_sampler, var_texcoord0);
	if (radius <= 0) return;
	separation = max(separation, 1);
	fragColor = vec4(0);
	int count = 0;
	for (int i = -radius; i <= radius; ++i) {
		for (int j = -radius; j <= radius; ++j) {
			fragColor += texture(color_sampler, var_texcoord0 + vec2(i, j) * separation / resolution);
			++count;
		}
	}
	fragColor /= count;
}
