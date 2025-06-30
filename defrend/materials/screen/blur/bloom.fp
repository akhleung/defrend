#version 320 es

in mediump vec2 var_texcoord0;

uniform sampler2D color_sampler;

uniform bloom_fp {
	mediump vec4 params1;
	mediump vec4 params2;
};

out mediump vec4 fragColor;

void main() {
	mediump vec2	resolution	= vec2(params1.x, params1.y);
	mediump float	threshold	= params2.x;
	int		radius		= int(params2.y);
	mediump float	separation	= params2.z;
	mediump float	strength	= params2.w;

	mediump vec4 result = vec4(0);
	int count = 0;
	for (int i = -radius; i <= radius; ++i) {
		for (int j = -radius; j <= radius; ++j) {
			mediump vec4 color = texture(color_sampler, (gl_FragCoord.xy + (vec2(i, j) * separation)) / resolution);
			mediump float value = dot(color.rgb, vec3(0.21, 0.72, 0.07));
			result += value < threshold ? vec4(0) : color;
			++count;
		}
	}
	result /= float(count);
	result = mix(vec4(0), result, strength);
	fragColor = texture(color_sampler, var_texcoord0);
	fragColor.rgb += result.rgb;
}
