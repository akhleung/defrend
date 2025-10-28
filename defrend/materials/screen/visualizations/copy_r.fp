#version 420 core

in vec2 var_texcoord0;

uniform sampler2D input_sampler;

out vec4 frag_output;

void main() {
	frag_output = vec4(vec3(texture(input_sampler, var_texcoord0).r), 1.0);
}
