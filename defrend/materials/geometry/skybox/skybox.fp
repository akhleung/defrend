#version 420 core

in vec3 var_texcoord0;

uniform samplerCube	cubemap;

layout(location = 0) out vec4 frag_color;
layout(location = 1) out vec4 frag_normal;

void main() {
	frag_color = vec4(texture(cubemap, var_texcoord0).rgb, 0);
	frag_normal = vec4(0);

	#ifdef EDITOR
	// set alpha back to 1.0 to make things show up in the editor
	frag_color.a = 1.0;
	#endif
}
