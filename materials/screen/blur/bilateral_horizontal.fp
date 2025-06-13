#version 420

in vec2 var_texcoord0;

uniform sampler2D color_sampler;

uniform bilateral_blur_fp {
	vec4 params;
};

vec2	resolution			= vec2(params.x, params.y);
vec2	delta				= vec2(1, 0) / resolution;
float	gaussian_coeffs[5]	= float[] (0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);

out vec4 fragColor;

void main() {

	float normalizer = length(vec3(1));
	
	vec3 c = texture(color_sampler, var_texcoord0).rgb;
	vec3 result = c * gaussian_coeffs[0];
	float total = gaussian_coeffs[0];
	
	for (int i = 1; i < 5; ++i) {
		vec3 s = texture(color_sampler, var_texcoord0 + delta * i).rgb;
		float d = distance(c, s);
		float w = (1 - d * normalizer) * gaussian_coeffs[i];
		result += s * w;
		total += w;

		s = texture(color_sampler, var_texcoord0 - delta * i).rgb;
		d = distance(c, s);
		w = (1 - d * normalizer) * gaussian_coeffs[i];
		result += s * w;
		total += w;
	}
	fragColor = vec4(result / total, 1.0);
}
