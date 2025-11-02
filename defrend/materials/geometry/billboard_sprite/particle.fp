#version 420 core

in vec3 var_normal;
in vec2 var_texcoord0;

uniform sampler2D albedo_map;

uniform particle_fp {
	vec4 spec_glow_dith;
};

layout(location = 0) out vec4 albedo_out;
layout(location = 1) out vec4 normal_out;

bool even(float x) {
	return int(x) % 2 == 0;
}

bool odd(float x) {
	return !even(x);
}

void main() {
	float x = gl_FragCoord.x;
	float y = gl_FragCoord.y;
	bool dither = spec_glow_dith.z > 0 && (even(x) && odd(y) || odd(x) && even(y));
	vec4 albedo	= texture(albedo_map, var_texcoord0);
	if (dither || albedo.a == 0) discard; // avoid writing to the depth buffer, normals, etc

	float specular = spec_glow_dith.x;
	float emissive = spec_glow_dith.y;

	albedo_out		= vec4(albedo.rgb, emissive);
	normal_out		= vec4(var_normal * 0.5 + 0.5, specular);

	#ifdef EDITOR
	// set alpha back to 1.0 to make things show up in the editor
	albedo_out.a = 1;
	normal_out.a = 0;
	#endif
}
