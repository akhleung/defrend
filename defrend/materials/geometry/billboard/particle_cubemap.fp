#version 420 core

in vec3 var_frag_pos;
in vec2 var_texcoord0;

uniform sampler2D albedo_map;

uniform particle_shadow_fp {
	vec4 spec_glow_dith;
	vec4 radius;
};

layout(location = 0) out float frag_out;

bool even(float x) {
	return int(x) % 2 == 0;
}

bool odd(float x) {
	return !even(x);
}

void main() {
	float x = gl_FragCoord.x;
	float y = gl_FragCoord.y;
	bool dither = spec_glow_dith.z > 0 && (even(x) ? odd(y) : even(y)); // consider making this sparser
	vec4 albedo	= texture(albedo_map, var_texcoord0);
	if (dither || albedo.a == 0) discard; // avoid writing to the depth buffer, normals, etc

	// write linear distance to the light origin for cubemap/omnidirectional shadow mapping
	frag_out = length(var_frag_pos) / radius.x;
}
