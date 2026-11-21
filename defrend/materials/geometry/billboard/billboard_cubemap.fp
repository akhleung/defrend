#version 420 core

in vec3 var_frag_pos;
in vec2 var_texcoord0;

uniform sampler2D albedo_map;

uniform particle_shadow_fp {
	vec4 radius;
};

layout(location = 0) out float frag_out;

void main() {
	if (texture(albedo_map, var_texcoord0).a == 0) discard; // avoid writing to the depth buffer, normals, etc
	// write linear distance to the light origin for cubemap/omnidirectional shadow mapping
	frag_out = length(var_frag_pos) / radius.x;
}
