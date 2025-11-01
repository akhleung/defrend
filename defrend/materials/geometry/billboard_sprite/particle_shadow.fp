#version 420 core

in vec3 var_normal;
in vec2 var_texcoord0;

uniform sampler2D albedo_map;

void main() {
	vec4 albedo	= texture(albedo_map, var_texcoord0);
	if (albedo.a == 0) discard; // avoid writing to the depth buffer, normals, etc
}
