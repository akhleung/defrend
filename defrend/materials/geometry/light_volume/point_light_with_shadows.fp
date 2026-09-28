#version 420 core
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/lighting_functions.glsl"

#define PI 3.141592654
#define X vec3(1, 0, 0)
#define Y vec3(0, 1, 0)

in vec3 var_center;
in vec3 var_center_w;
in vec3 var_color;
in float var_radius;
in float var_attn;
#ifdef EDITOR
in vec3 var_normal;
#endif

uniform sampler2D depth_buffer;
uniform sampler2D normal_sampler;
uniform sampler2D shadow_map;

uniform point_light_fp {
	// these matrices == light projection * light view (so they require a position in world space)
	mat4 mtx_nx;
	mat4 mtx_px;
	mat4 mtx_ny;
	mat4 mtx_py;
	mat4 mtx_nz;
	mat4 mtx_pz;
    vec4 frustum_corner;
    vec4 frustum_terms;
	vec4 params; // x: stride, y: y_offset, z: index, w: bias
	mat4 mtx_view_inv;
};

int stride = int(params.x);
int y_offset = int(params.y);
float bias = params.w;

layout(location = 0) out vec4 light_out;

void main() {
	ivec2 frag_coord = ivec2(gl_FragCoord.xy);
	float depth = texelFetch(depth_buffer, frag_coord, 0).r;
	float z = linearizeDepth(depth, frustum_terms.xyz);
	vec2 screen_uv = gl_FragCoord.xy / textureSize(depth_buffer, 0);
	vec3 geom_pos = viewPosFromLinearDepth(z, screen_uv, frustum_corner.xyz);
	vec4 normal_sample = texelFetch(normal_sampler, frag_coord, 0);
	float shininess = normal_sample.a * 255;
	vec3 to_light = var_center - geom_pos;
	float d = length(to_light);
	if (d > var_radius) discard;

	// Determine which shadow map to sample. Relative to the center of the light, the fragment position's component with
	// the highest magnitude should indicate the relevant cube face.
	vec3 normal = normalize(normal_sample.xyz * 2.0 - 1.0);
	vec4 geom_pos_w = mtx_view_inv * vec4(geom_pos + normal * bias, 1.0);
	vec3 geom_pos_l = geom_pos_w.xyz - var_center_w;
	float magx = abs(geom_pos_l.x), magy = abs(geom_pos_l.y), magz = abs(geom_pos_l.z);
	mat4 mtx_light;
	float x_offset;
	if (magx > magy && magx > magz) {
		bool neg = sign(geom_pos_l.x) < 0;
		mtx_light = neg ? mtx_nx : mtx_px;
		x_offset = neg ? 0 : stride;
	} else if (magy > magx && magy > magz) {
		bool neg = sign(geom_pos_l.y) < 0;
		mtx_light = neg ? mtx_ny : mtx_py;
		x_offset = neg ? 2 * stride : 3 * stride;
	} else {
		bool neg = sign(geom_pos_l.z) < 0;
		mtx_light = neg ? mtx_nz : mtx_pz;
		x_offset = neg ? 4 * stride : 5 * stride;
	}

	// TODO: PCF / Poisson filtering, distance fade-out
	vec4 geom_pos_s = mtx_light * geom_pos_w;
	geom_pos_s /= geom_pos_s.w;
	ivec2 shadow_xy = ivec2((geom_pos_s.xy * 0.5 + 0.5) * stride);
	shadow_xy += ivec2(x_offset, y_offset);
	shadow_xy = clamp(shadow_xy, ivec2(x_offset, y_offset), ivec2(x_offset + stride, y_offset + stride));

	float occludee_z = geom_pos_s.z * 0.5 + 0.5;
	float is_lit = texelFetch(shadow_map, shadow_xy, 0).r < occludee_z ? 0 : 1;

	vec3 to_view = -geom_pos;
	vec3 to_light_normalized = normalize(to_light);
	float diff = diffuse(to_light_normalized, normal);
	float spec = specular(normalize(to_view), to_light_normalized, normal, shininess);
	float attn = attn_inv_pow(d, var_radius, var_attn);
	light_out = vec4(var_color * diff * attn, spec * attn) * is_lit;

	#ifdef EDITOR // visualization for viewing point light volumes in the editor
	vec3 lat_normal = normalize(vec3(var_normal.x, 0, var_normal.z));
	vec2 dots = abs(vec2(dot(lat_normal, X), dot(var_normal, Y)));
	vec2 rads = acos(dots);
	vec2 degs = floor(rads * 180 / PI);
	vec2 rems = fract(degs / 24);
	if (rems.x == 0 || rems.y == 0) {
		light_out = vec4(var_color, 1.0);
	} else if (int(gl_FragCoord.y) % 4 == 0 && int(gl_FragCoord.x) % 2 == 0) {
		light_out = vec4(var_color, 1.0);
	} else if (int(gl_FragCoord.y) % 4 == 0) {
		discard;
	} else if (int(gl_FragCoord.y) % 2 == 0 && int(gl_FragCoord.x) % 2 != 0) {
		light_out = vec4(var_color, 1.0);
	} else {
		discard;
	}
	#endif
}
