#version 420 core

in vec2 var_texcoord0;

uniform sampler2D input_sampler;

out vec4 frag_output;

void main() {
	frag_output = vec4(texture(input_sampler, var_texcoord0).rgb, 1.0);
}
