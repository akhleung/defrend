#version 420

uniform sampler2D color_sampler;

uniform box_blur_fp {
	vec4 resolution;
};

out vec4 fragColor;

void main() {
	vec2 texSize  = resolution.xy;
	vec2 texCoord = gl_FragCoord.xy / texSize;

	fragColor = texture(color_sampler, texCoord);

	int radius = 1;
	if (radius <= 0) return;

	float separation = 2.0;
	separation = max(separation, 1);

	fragColor.rgb = vec3(0);

	float count = 0.0;

	for (int i = -radius; i <= radius; ++i) {
		for (int j = -radius; j <= radius; ++j) {
			fragColor.rgb += texture(color_sampler, (gl_FragCoord.xy + (vec2(i, j) * separation)) / texSize).rgb;
			count += 1.0;
		}
	}

	fragColor.rgb /= count;
}
