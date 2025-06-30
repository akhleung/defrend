#version 320 es

in mediump vec3 var_texcoord0;

uniform samplerCube	cubemap;

layout(location = 0) out mediump vec4 frag_color;

void main() {
	frag_color = texture(cubemap, var_texcoord0);
}
