#version 320 es
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/lighting_functions.glsl"

in mediump vec2 var_texcoord0;

uniform sampler2D depth_buffer;
uniform sampler2D focused_sampler;
uniform sampler2D blurred_sampler;

uniform dof_fp {
	mediump vec4 params;
	mediump vec4 frustum_terms;
};

out mediump vec4 fragColor;

void main() {
	mediump float focal_depth = params.x;
	mediump float blur_start = params.y;
	mediump float blur_full = params.z;

	mediump float z = linearizeDepth(texture(depth_buffer, var_texcoord0).r, frustum_terms.xyz);
	mediump float blurriness = smoothstep(blur_start, blur_full, abs(focal_depth + z));
	mediump vec4 focused_frag = texture(focused_sampler, var_texcoord0);
	mediump vec4 blurred_frag = texture(blurred_sampler, var_texcoord0);
	fragColor = mix(focused_frag, blurred_frag, blurriness);
}
