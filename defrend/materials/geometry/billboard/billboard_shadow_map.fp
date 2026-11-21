#version 420 core

in vec2 var_texcoord0;

uniform sampler2D albedo_map;

void main() {
	if (texture(albedo_map, var_texcoord0).a == 0) discard; // avoid writing to the depth buffer, normals, etc
}
