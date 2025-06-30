#version 320 es
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/lighting_functions.glsl"

in mediump vec3 var_center;
in mediump vec4 var_color;
in mediump vec4 var_radii;

uniform sampler2D depth_buffer;
uniform sampler2D normal_sampler;
uniform sampler2D spec_glow_sampler;

uniform point_light_fp {
	mediump vec4 resolution;
    mediump vec4 frustum_corner;
    mediump vec4 frustum_terms;
};

layout(location = 0) out mediump vec4 diff_out;
layout(location = 1) out mediump vec4 spec_out;

void main() {
	mediump vec2 texcoord = gl_FragCoord.xy / resolution.xy;
    mediump float depth = texture(depth_buffer, texcoord).r;
	mediump float z = linearizeDepth(depth, frustum_terms.xyz);
	mediump vec3 geom_pos = viewPosFromLinearDepth(z, texcoord, frustum_corner.xyz);
	mediump vec4 normal_sample = texture(normal_sampler, texcoord);
	mediump vec4 spec_sample = texture(spec_glow_sampler, texcoord);
	mediump float shininess = spec_sample.r * 255.0;
	mediump vec3 to_light = var_center - geom_pos;
	mediump float d = length(to_light);
	if (d > var_radii.y) discard;
	mediump vec3 to_view = -geom_pos;
	mediump vec3 normal = normalize(normal_sample.xyz * 2.0 - 1.0);
	mediump vec3 to_light_normalized = normalize(to_light);
	mediump float diff = max(dot(normal, to_light_normalized), 0.0);
	mediump float spec = specular(normalize(to_view), to_light_normalized, normal, shininess);
	mediump float attn = attenuation(d, var_radii.x, var_radii.y);
	diff_out = var_color * diff * attn;
	spec_out = var_color * spec * attn;
}
