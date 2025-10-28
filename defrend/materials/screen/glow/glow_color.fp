#version 420 core

in vec2 var_texcoord0;

uniform sampler2D color_sampler;

out vec4 frag_output;

void main() {
	vec4 color_sample = texture(color_sampler, var_texcoord0);
	vec3 color = color_sample.rgb;
	float emissive = color_sample.a;
	frag_output = vec4(color * emissive, 1.0);
}
