#version 420

in vec2 var_texcoord0;

uniform sampler2D color_sampler;

uniform box_blur_fp {
	vec4 params;
};

vec2 resolution = vec2(params.x, params.y);
int samples = int(params.z);
float radius = params.w;

out vec4 fragColor;

void main() {
	fragColor = texture(color_sampler, var_texcoord0);
	if (samples <= 0) return;
	radius = max(radius, 1);
	fragColor = vec4(0);
	int count = 0;
	for (int i = -samples; i <= samples; ++i) {
		for (int j = -samples; j <= samples; ++j) {
			fragColor += texture(color_sampler, (gl_FragCoord.xy + (vec2(i, j) * radius)) / resolution);
			++count;
		}
	}
	fragColor /= count;
}
