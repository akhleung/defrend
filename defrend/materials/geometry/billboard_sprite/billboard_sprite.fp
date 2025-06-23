#version 420 core

in vec3 var_frag_pos;
in vec3 var_normal;
in vec2 var_texcoord0;

uniform sampler2D diffuse_map;
uniform sampler2D normal_map;
uniform sampler2D spec_glow_map;

layout(location = 0) out vec4 diffuse_out;
layout(location = 1) out vec4 normal_out;
layout(location = 2) out vec4 spec_glow_out;

mat3 get_tbn_mtx() {
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

vec3 get_perturb_normal(vec2 texture_coord, mat3 tbn_mtx) {
	// mediump mat3 tbn_mtx = get_tbn_mtx(world_normal, -view_direction, texture_coord);
	vec3 normal_map_color = texture(normal_map, texture_coord).xyz;
	// mediump vec3 perturb_normal = normal_map_color * (255.0 / 127.0) - vec3(128.0 / 127.0);
	vec3 perturb_normal = normal_map_color * 2.0 - 1.0;
	// if (surface.z > 0.5) {
	//     // This is the DirectX normals map format
	//     perturb_normal.y = -perturb_normal.y;
	// }
	return normalize(tbn_mtx * perturb_normal);
}

void main() {
	vec4 diffuse	= texture(diffuse_map, var_texcoord0);
	if (diffuse.a == 0) discard; // avoid writing to the depth buffer, normals, etc
	diffuse_out		= diffuse;
	normal_out		= vec4(get_perturb_normal(var_texcoord0, get_tbn_mtx()) * 0.5 + 0.5, 1);
	spec_glow_out	= texture(spec_glow_map, var_texcoord0);
}
