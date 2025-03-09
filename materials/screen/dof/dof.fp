#version 420
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/position_from_depth.glsl"

in vec2 var_texcoord0;

uniform sampler2D depth_buffer;
uniform sampler2D color_sampler;

uniform dof_fp {
	vec4 params1;
	vec4 params2;
	vec4 frustum_terms;
};

vec2 resolution = vec2(params1.x, params1.y);
float focal_depth = params2.x;
float blur_start = params2.y;
float blur_full = params2.z;
float radius = params2.w;

out vec4 fragColor;

// TODO: consider doing this in two passes (i.e., create a fully blurred render and mix it with an in-focus render)
void main() {
	float z = linearizeDepth(texture(depth_buffer, var_texcoord0).r, frustum_terms.xyz);
	float r = smoothstep(blur_start, blur_full, abs(focal_depth + z)) * radius;
	int samples = r == 0 ? 0 : 1;
	float count = pow(2 * samples + 1, 2);
	fragColor = vec4(0, 0, 0, 1);
	for (int i = -samples; i <= samples; ++i) {
		for (int j = -samples; j <= samples; ++j) {
			fragColor += texture(color_sampler, (gl_FragCoord.xy + (vec2(i, j) * r)) / resolution);
		}
	}
	fragColor /= count;
}
