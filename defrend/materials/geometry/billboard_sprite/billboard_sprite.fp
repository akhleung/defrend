#version 420 core

in vec3 var_frag_pos;
in vec3 var_normal;
in vec2 var_texcoord0;

uniform sampler2D albedo_map;
uniform sampler2D normal_map;
uniform sampler2D spec_glow_map;

layout(location = 0) out vec4 albedo_out;
layout(location = 1) out vec4 normal_out;

mat3 get_tbn() {
	vec3 d_vd_x = dFdx(var_frag_pos);
	vec3 d_vd_y = dFdy(var_frag_pos);

	vec2 d_tc_x = dFdx(var_texcoord0);
	vec2 d_tc_y = dFdy(var_texcoord0);

	vec3 d_vd_y_cross = cross(d_vd_y, var_normal);
	vec3 d_vd_x_cross = cross(var_normal, d_vd_x);

	vec3 tangent = d_vd_y_cross * d_tc_x.x + d_vd_x_cross * d_tc_y.x;
	vec3 bitangent = d_vd_y_cross * d_tc_x.y + d_vd_x_cross * d_tc_y.y;

	float inv_max = inversesqrt(max(dot(tangent, tangent), dot(bitangent, bitangent)));
	return mat3(tangent * inv_max, bitangent * inv_max, var_normal);
}

vec3 perturb_normal() {
	return normalize(get_tbn() * (texture(normal_map, var_texcoord0).xyz * 2.0 - 1.0));
}

void main() {
	vec4 diffuse	= texture(albedo_map, var_texcoord0);
	if (diffuse.a == 0) discard; // avoid writing to the depth buffer, normals, etc
	vec4 spec_glow	= texture(spec_glow_map, var_texcoord0);
	albedo_out		= vec4(diffuse.rgb, spec_glow.g);
	normal_out		= vec4(perturb_normal() * 0.5 + 0.5, spec_glow.r);

	#ifdef EDITOR
	// set alpha back to 1.0 to make things show up in the editor
	albedo_out.a = 1.0;
	normal_out.a = 1.0;
	#endif
}
