#version 320 es

in mediump vec2 var_texcoord0;

uniform sampler2D color_sampler;

uniform gaussian_blur_fp {
	mediump vec4 params;
};

mediump float	weight[5]	= float[] (0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);

out mediump vec4 fragColor;

void main() {

	mediump vec2	resolution	= vec2(params.x, params.y);
	mediump vec2	delta		= vec2(0, 1) / resolution;

	mediump vec3 result = texture(color_sampler, var_texcoord0).rgb * weight[0];
	for (int i = 1; i < 5; ++i) {
		result += texture(color_sampler, var_texcoord0 + delta * float(i)).rgb * weight[i];
		result += texture(color_sampler, var_texcoord0 - delta * float(i)).rgb * weight[i];
	}
	fragColor = vec4(result, 1.0);
}
