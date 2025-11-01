#version 420 core

in vec3 var_normal;
in vec2 var_texcoord0;

uniform sampler2D albedo_map;

uniform particle_fp {
	vec4 spec_glow_params;
};

layout(location = 0) out vec4 albedo_out;
layout(location = 1) out vec4 normal_out;

void main() {
	vec4 albedo	= texture(albedo_map, var_texcoord0);
	if (albedo.a == 0) discard; // avoid writing to the depth buffer, normals, etc

	float specular = spec_glow_params.x;
	float emissive = spec_glow_params.y;

	albedo_out		= vec4(albedo.rgb, emissive);
	normal_out		= vec4(var_normal * 0.5 + 0.5, specular);

	#ifdef EDITOR
	// set alpha back to 1.0 to make things show up in the editor
	albedo_out.a = 1;
	normal_out.a = 0;
	#endif
}
