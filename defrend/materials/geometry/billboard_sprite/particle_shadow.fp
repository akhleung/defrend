#version 420 core

in vec3 var_normal;
in vec2 var_texcoord0;

uniform sampler2D albedo_map;

uniform particle_shadow_fp {
	vec4 spec_glow_params;
};

bool even(float x) {
	return int(x) % 2 == 0;
}

bool odd(float x) {
	return !even(x);
}

void main() {
	float x = gl_FragCoord.x;
	float y = gl_FragCoord.y;
	bool dither = spec_glow_params.z > 0 && (even(x) && odd(y) || odd(x) && even(y)); // consider making this sparser
	vec4 albedo	= texture(albedo_map, var_texcoord0);
	if (dither || albedo.a == 0) discard; // avoid writing to the depth buffer, normals, etc
}
