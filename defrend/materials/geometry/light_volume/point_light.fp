#version 420 core
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/lighting_functions.glsl"

#define PI 3.141592654
#define HALF_PI 1.570796327

in vec3 var_center;
in vec4 var_color;
in float var_radius;
#ifdef EDITOR
in vec3 var_normal;
in vec3 var_vertex;
#endif

uniform sampler2D depth_buffer;
uniform sampler2D normal_sampler;
uniform sampler2D spec_glow_sampler;

uniform point_light_fp {
	vec4 resolution;
    vec4 frustum_corner;
    vec4 frustum_terms;
};

layout(location = 0) out vec4 diff_out;
layout(location = 1) out vec4 spec_out;

void main() {
	vec2 texcoord = gl_FragCoord.xy / resolution.xy;
    float depth = texture(depth_buffer, texcoord).r;
	float z = linearizeDepth(depth, frustum_terms.xyz);
	vec3 geom_pos = viewPosFromLinearDepth(z, texcoord, frustum_corner.xyz);
	vec4 normal_sample = texture(normal_sampler, texcoord);
	vec4 spec_sample = texture(spec_glow_sampler, texcoord);
	float shininess = spec_sample.r * 255;
	vec3 to_light = var_center - geom_pos;
	float d = length(to_light);
	if (d > var_radius) discard;
	vec3 to_view = -geom_pos;
	vec3 normal = normalize(normal_sample.xyz * 2.0 - 1.0);
	vec3 to_light_normalized = normalize(to_light);
	float diff = diffuse(to_light_normalized, normal);
	float spec = specular(normalize(to_view), to_light_normalized, normal, shininess);
	float attn = attn_circ(d, var_radius);
	diff_out = var_color * diff * attn;
	spec_out = var_color * spec * attn;

	#ifdef EDITOR // visualization for viewing point light volumes in the editor
	float dp = abs(dot(var_normal, vec3(0, 1, 0)));
	float rad = acos(dp);
	float deg = floor(rad * 180 / PI);
	if (fract(deg / 4) == 0) {
		diff_out = var_color;
	} else {
		discard;
	}
	#endif
}
