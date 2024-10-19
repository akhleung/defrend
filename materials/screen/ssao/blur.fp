#version 420 core

in vec2 var_texcoord0;

uniform sampler2D ssao_sampler;

uniform blur_fp {
	vec4 resolution;
};

out vec4 frag_color;

float random (vec4 seed4) {
    float dot_product = dot(seed4, vec4(12.9898,78.233,45.164,94.673));
    return fract(sin(dot_product) * 43758.5453);
}

void main() {
	// vec2 texelSize = 1.0 / textureSize(ssao_sampler, 0);
	vec4 ssao = vec4(0.0);
	for (int i = 0; i < 4; i++) {
		ssao += texture(ssao_sampler, var_texcoord0 + (random(vec4(var_texcoord0, -var_texcoord0) * vec4(float(-i))) / 200.0));
		// ssao += texture(ssao_sampler, var_texcoord0 + (random(vec4(-var_texcoord0, var_texcoord0) * vec4(float(i)))/100.0));
	}
	// ssao /= 8.0;
	ssao /= 4.0;
	frag_color.g = ssao.g;


    // vec2 texelSize = 1.0 / (resolution.xy);
	// // texelSize = 1.0 / textureSize(ssao_sampler, 0);
    // float result = 0.0;
    // for (int x = -2; x < 2; ++x) {
    //     for (int y = -2; y < 2; ++y) {
    //         vec2 offset = vec2(float(x), float(y)) * texelSize;
    //         result += texture(ssao_sampler, var_texcoord0 + offset).r;
    //     }
    // }
	// result = result / 16;
	// // result = 1.0 - result;
    // frag_color.g = result;
	// // frag_color = texture(ssao_sampler, var_texcoord0);
}
