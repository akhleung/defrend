#version 320 es

in mediump vec2 var_texcoord0;

uniform sampler2D color_sampler;

uniform box_blur_fp {
	mediump vec4 params;
};

out mediump vec4 fragColor;

void main() {
	mediump vec2 resolution = vec2(params.x, params.y);
	int radius = int(params.z);
	mediump float separation = params.w;

	fragColor = texture(color_sampler, var_texcoord0);
	if (radius <= 0) return;
	separation = max(separation, 1.0);
	fragColor = vec4(0);
	int count = 0;
	for (int i = -radius; i <= radius; ++i) {
		for (int j = -radius; j <= radius; ++j) {
			fragColor += texture(color_sampler, var_texcoord0 + vec2(i, j) * separation / resolution);
			++count;
		}
	}
	fragColor /= float(count);
}
