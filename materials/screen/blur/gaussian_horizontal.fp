#version 420

in vec2 var_texcoord0;

uniform sampler2D color_sampler;

uniform gaussian_blur_fp {
	vec4 params;
};

vec2	resolution	= vec2(params.x, params.y);
vec2	delta		= vec2(1, 0) / resolution;
float	weight[5]	= float[] (0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);
float	white		= length(vec3(1));

out vec4 fragColor;

void main() {
	vec3	samp	= texture(color_sampler, var_texcoord0).rgb;
	float	w		= weight[0] * (white - length(samp)/2);
	vec3	result	= samp * w;
	float	total	= w;

	for (int i = 1; i < 5; ++i) {
		samp	= texture(color_sampler, var_texcoord0 + delta * i).rgb;
		w		= weight[i] * (white - length(samp)/2);
		result	+= samp * w;
		total	+= w;

		samp	= texture(color_sampler, var_texcoord0 - delta * i).rgb;
		w		= weight[i] * (white - length(samp)/2);
		result	+= samp * w;
		total	+= w;
	}
	fragColor = vec4(result / total, 1.0);
}
