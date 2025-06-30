#version 320 es

in mediump vec2 var_texcoord0;

uniform sampler2D color_sampler;

uniform dilate_fp {
	mediump vec4 params1;
	mediump vec4 params2;
};

out mediump vec4 fragColor;

void main() {
	mediump vec2 resolution = vec2(params1.x, params1.y);
	mediump float min_threshold = params2.x;
	mediump float max_threshold = params2.y;
	int radius = int(params2.z);
	mediump float separation = params2.w;
	mediump vec3 values = vec3(0.21, 0.72, 0.07);

	fragColor = texture(color_sampler, var_texcoord0);
	mediump vec4 max_color = fragColor;
	mediump float max_value = 0.0;
	for (int i = -radius; i <= radius; ++i) {
		for (int j = -radius; j <= radius; ++j) {
			mediump vec4 sample_color = texture(color_sampler, (gl_FragCoord.xy + (vec2(i, j) * separation)) / resolution);
			mediump float sample_value = dot(sample_color.rgb, values);
			if (sample_value > max_value) {
				max_value = sample_value;
				max_color = sample_color;
			}
		}
	}
	fragColor.rgb = mix(fragColor.rgb, max_color.rgb, smoothstep(min_threshold, max_threshold, max_value));
}
