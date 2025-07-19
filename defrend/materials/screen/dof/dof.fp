#version 420
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/lighting_functions.glsl"

in vec2 var_texcoord0;

uniform sampler2D depth_buffer;
uniform sampler2D focused_sampler;
uniform sampler2D blurred_sampler;

uniform dof_fp {
	vec4 params;
	vec4 frustum_terms;
};

float focal_depth = params.x;
float blur_start = params.y;
float blur_full = params.z;

out vec4 fragColor;

void main() {
	float z = linearizeDepth(texture(depth_buffer, var_texcoord0).r, frustum_terms.xyz);
	float blurriness = smoothstep(blur_start, blur_full, abs(focal_depth + z));
	vec4 focused_frag = texture(focused_sampler, var_texcoord0);
	vec4 blurred_frag = texture(blurred_sampler, var_texcoord0);
	fragColor = mix(focused_frag, blurred_frag, blurriness);
}
