#version 420

uniform sampler2D color_sampler;

uniform box_blur_fp {
	vec4 params;
};

vec2 resolution = vec2(params.x, params.y);
int samples = int(params.z);
float radius = params.w;

out vec4 fragColor;

void main() {
	vec2 texCoord = gl_FragCoord.xy / resolution;

	fragColor = texture(color_sampler, texCoord);

	if (samples <= 0) return;

	radius = max(radius, 1);

	fragColor.rgb = vec3(0);

	float count = 0.0;

	for (int i = -samples; i <= samples; ++i) {
		for (int j = -samples; j <= samples; ++j) {
			fragColor.rgb += texture(color_sampler, (gl_FragCoord.xy + (vec2(i, j) * radius)) / resolution).rgb;
			count += 1.0;
		}
	}

	fragColor.rgb /= count;
}
