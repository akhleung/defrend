#version 420

in vec2 var_texcoord0;

uniform sampler2D color_sampler;

uniform dilate_fp {
	vec4 params;
};

vec2 resolution = textureSize(color_sampler, 0);
float min_threshold = params.x;
float max_threshold = params.y;
int radius = int(params.z);
float separation = params.w;
vec3 values = vec3(0.21, 0.72, 0.07);

layout(location = 0) out vec4 fragColor;
layout(location = 1) out vec4 whatever;

void main() {
	fragColor = texture(color_sampler, var_texcoord0);
	vec4 max_color = fragColor;
	float max_value = 0;
	for (int i = -radius; i <= radius; ++i) {
		for (int j = -radius; j <= radius; ++j) {
			vec4 sample_color = texture(color_sampler, (gl_FragCoord.xy + (vec2(i, j) * separation)) / resolution);
			float sample_value = dot(sample_color.rgb, values);
			if (sample_value > max_value) {
				max_value = sample_value;
				max_color = sample_color;
			}
		}
	}
	fragColor.rgb = mix(fragColor.rgb, max_color.rgb, smoothstep(min_threshold, max_threshold, max_value));
	whatever = vec4(0);
}
