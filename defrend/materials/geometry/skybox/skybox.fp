#version 420 core

in vec3 var_texcoord0;

uniform samplerCube	cubemap;

layout(location = 0) out vec4 frag_color;
layout(location = 1) out vec4 frag_normal;
layout(location = 2) out vec4 frag_spec_glow;

void main() {
	frag_color = texture(cubemap, var_texcoord0);
	frag_normal = vec4(0);
	frag_spec_glow = vec4(0);
}
