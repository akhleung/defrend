#version 420 core
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/lighting_functions.glsl"

#define PI 3.141592654

in vec3 var_source;
in vec3 var_light_dir;
in vec3 var_color;
in float var_spread;
in float var_range;
in float var_start;
in float var_range_attn;
in float var_spread_attn;
#ifdef EDITOR
in vec3 var_frag_pos;
in vec3 var_edge_pos;
in vec3 var_lat_norm;
in vec3 var_lat_axis;
in float var_pcnt_start;
#endif

uniform sampler2D depth_buffer;
uniform sampler2D normal_sampler;

uniform spot_light_fp {
    vec4 frustum_corner;
    vec4 frustum_terms;
};

layout(location = 0) out vec4 light_out;

void main() {

	vec2 texcoord = gl_FragCoord.xy / textureSize(depth_buffer, 0);
    float depth = texture(depth_buffer, texcoord).r;
	float z = linearizeDepth(depth, frustum_terms.xyz);
	vec3 geom_pos = viewPosFromLinearDepth(z, texcoord, frustum_corner.xyz);
	vec4 normal_sample = texture(normal_sampler, texcoord);
	float shininess = normal_sample.a * 255;

	vec3 to_light = var_source - geom_pos;
	vec3 to_light_normalized = normalize(to_light);
	float d = length(to_light);
	float a = dot(normalize(geom_pos - var_source), var_light_dir);
	if (a < var_spread || d > var_range || d < var_start) discard;
	vec3 to_view = -geom_pos;
	vec3 normal = normalize(normal_sample.xyz * 2.0 - 1.0);
	float diff = diffuse(to_light_normalized, normal);
	float spec = specular(normalize(to_view), to_light_normalized, normal, shininess);
	float attn_range = attn_inv_pow(d - var_start, var_range - var_start, var_range_attn);
	float attn_spread = attn_inv_pow(1 - a, 1 - var_spread, var_spread_attn);
	float attn = attn_range * attn_spread;
	light_out = vec4(var_color * diff * attn, spec * attn);

	#ifdef EDITOR // visualization for viewing spot light volumes in the editor
	float frag_dist = distance(var_source, var_frag_pos);
	float edge_dist = distance(var_source, var_edge_pos);
	float pcnt_dist = floor(100 * (frag_dist / edge_dist));
	float step_size = 5;
	float rem = fract(pcnt_dist / step_size);

	float dotl = dot(normalize(var_lat_norm - vec3(0, var_lat_norm.y, 0)), var_lat_axis);
	float radl = acos(dotl);
	float degl = floor(radl * 180 / PI);
	float reml = fract(degl / 12);
	if (pcnt_dist < var_pcnt_start) {
		discard;
	} else if (abs(var_pcnt_start - pcnt_dist) < 1) {
		light_out = vec4(var_color, 1.0);
	} else if (rem == 0 || pcnt_dist > 98 || reml == 0) {
		light_out = vec4(var_color, 1.0);
	} else {
		discard;
	}
	#endif
}
