#version 420 core
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/position_from_depth.glsl"

in vec3 var_center;
in vec4 var_color;
in vec4 var_radii;

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

float specular(vec3 viewdir, vec3 lightdir, vec3 norm, float shiny) {
    vec3 H = normalize(viewdir + lightdir);
    return shiny == 0 ? 0 : pow(max(dot(norm, H), 0.0), shiny);
}

float attenuation(float d, float r_inner, float r_outer) {
    float falloff = 1.0 - smoothstep(r_inner, r_outer, d);
    return falloff * falloff;
}

void main() {
	vec2 texcoord = gl_FragCoord.xy / resolution.xy;
    float depth = texture(depth_buffer, texcoord).r;
	float z = linearizeDepth(depth, frustum_terms.xyz);
	vec3 geom_pos = viewPosFromLinearDepth(z, texcoord, frustum_corner.xyz);
	vec4 normal_sample = texture(normal_sampler, texcoord);
	float shininess = texture(spec_glow_sampler, texcoord).r * 255;
	vec3 to_light = var_center - geom_pos;
	float d = length(to_light);
	if (d > var_radii.y) discard;
	vec3 to_view = -geom_pos;
	vec3 normal = normalize(normal_sample.xyz * 2.0 - 1.0);
	vec3 to_light_normalized = normalize(to_light);
	float diff = max(dot(normal, to_light_normalized), 0.0);
	float spec = specular(normalize(to_view), to_light_normalized, normal, shininess);
	float attn = attenuation(d, var_radii.x, var_radii.y);
	diff_out = var_color * diff * attn;
	spec_out = var_color * spec * attn;
}
