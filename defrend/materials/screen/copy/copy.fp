#version 420 core
#extension GL_ARB_shading_language_include : require

in vec2 var_texcoord0;

uniform sampler2D input_sampler;

out vec4 frag_color;

void main() {
	frag_color = texture(input_sampler, var_texcoord0);
}
