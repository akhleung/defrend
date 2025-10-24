#version 420 core

in vec2 var_texcoord0;

uniform sampler2D glow_sampler;
uniform sampler2D color_sampler;

out vec4 frag_output;

void main() {
	float emissive = texture(glow_sampler, var_texcoord0).g;
	vec3 color = texture(color_sampler, var_texcoord0).rgb;
	frag_output = vec4(color * emissive, 1.0);
}
