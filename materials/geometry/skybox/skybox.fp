#version 420 core

in vec3 var_texcoord0;

uniform samplerCube	cubemap;

layout(location = 0) out vec4 frag_color;

void main() {
	frag_color = texture(cubemap, var_texcoord0);
}
