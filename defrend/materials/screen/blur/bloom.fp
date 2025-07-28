#version 420

in vec2 var_texcoord0;

uniform sampler2D color_sampler;

uniform bloom_fp {
	vec4 params1;
	vec4 params2;
};

vec2	resolution	= vec2(params1.x, params1.y);
float	threshold	= params2.x;
int		radius		= int(params2.y);
float	separation	= params2.z;
float	strength	= params2.w;

layout(location = 0) out vec4 fragColor;

void main() {
	vec4 result = vec4(0);
	int count = 0;
	for (int i = -radius; i <= radius; ++i) {
		for (int j = -radius; j <= radius; ++j) {
			vec4 color = texture(color_sampler, (gl_FragCoord.xy + (vec2(i, j) * separation)) / resolution);
			float value = dot(color.rgb, vec3(0.21, 0.72, 0.07));
			result += value < threshold ? vec4(0) : color;
			++count;
		}
	}
	result /= count;
	result = mix(vec4(0), result, strength);
	fragColor = texture(color_sampler, var_texcoord0);
	fragColor.rgb += result.rgb;
}
