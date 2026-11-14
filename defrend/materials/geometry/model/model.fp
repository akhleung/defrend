#version 420 core

in vec3 var_frag_pos;
in vec3 var_normal;
in vec2 var_texcoord0;
in mat3 var_tbn;

uniform sampler2D albedo_map;
uniform sampler2D normal_map;
uniform sampler2D spec_glow_map;

layout(location = 0) out vec4 albedo_out;
layout(location = 1) out vec4 normal_out;

vec3 perturb_normal() {
	return normalize(var_tbn * (texture(normal_map, var_texcoord0).xyz * 2.0 - 1.0));
}

void main() {
	vec4 spec_glow	= texture(spec_glow_map, var_texcoord0);
	albedo_out		= vec4(texture(albedo_map, var_texcoord0).rgb, spec_glow.g);
	normal_out		= vec4(perturb_normal() * 0.5 + 0.5, spec_glow.r);

	#ifdef EDITOR
	// set alpha back to 1.0 to make things show up in the editor
	albedo_out.a = 1.0;
	normal_out.a = 1.0;
	#endif
}
