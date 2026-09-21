#version 420 core
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/lighting_functions.glsl"

in vec2 var_texcoord0;

uniform sampler2D input_sampler;
uniform sampler2D depth_buffer;

uniform pack_coc_fp {
	vec4 params;
	vec4 frustum_terms;
};

float focal_depth = params.x;
float blur_start = params.y;
float blur_full = params.z;

layout(location = 0) out vec4 frag_output;

void main() {
	float z = linearizeDepth(texture(depth_buffer, var_texcoord0).r, frustum_terms.xyz);
	float dist = focal_depth + z;
	float coc = smoothstep(blur_start, blur_full, abs(dist)) * sign(dist);
	vec3 input_color = texture(input_sampler, var_texcoord0).rgb;
	frag_output = vec4(input_color, coc * 0.5 + 0.5);
}
