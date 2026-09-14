#version 420 core
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/lighting_functions.glsl"

// in vec2 var_texcoord0;

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

// void main() {
// 	float z = linearizeDepth(texture(depth_buffer, var_texcoord0).r, frustum_terms.xyz);
// 	float dist = focal_depth + z;
// 	float coc = smoothstep(blur_start, blur_full, abs(dist)) * -sign(dist);
// 	vec3 input_color = texture(input_sampler, var_texcoord0).rgb;
// 	frag_output = vec4(input_color, coc * 0.5 + 0.5);
// }

void main() {
	ivec2 c = 2 * ivec2(gl_FragCoord.xy);
	ivec2 r = c + ivec2(1, 0);
	ivec2 u = c + ivec2(0, 1);
	ivec2 d = c + ivec2(1, 1);

    vec4 color0 = texelFetch(input_sampler, c, 0);
    vec4 color1 = texelFetch(input_sampler, r, 0);
    vec4 color2 = texelFetch(input_sampler, u, 0);
    vec4 color3 = texelFetch(input_sampler, d, 0);

	float z0 = linearizeDepth(texelFetch(depth_buffer, c, 0).r, frustum_terms.xyz);
	float z1 = linearizeDepth(texelFetch(depth_buffer, r, 0).r, frustum_terms.xyz);
	float z2 = linearizeDepth(texelFetch(depth_buffer, u, 0).r, frustum_terms.xyz);
	float z3 = linearizeDepth(texelFetch(depth_buffer, d, 0).r, frustum_terms.xyz);

	float dist0 = focal_depth + z0;
	float dist1 = focal_depth + z1;
	float dist2 = focal_depth + z2;
	float dist3 = focal_depth + z3;

    float coc0 = smoothstep(blur_start, blur_full, abs(dist0)) * -sign(dist0);
    float coc1 = smoothstep(blur_start, blur_full, abs(dist1)) * -sign(dist1);
    float coc2 = smoothstep(blur_start, blur_full, abs(dist2)) * -sign(dist2);
    float coc3 = smoothstep(blur_start, blur_full, abs(dist3)) * -sign(dist3);

    vec4 color = (color0 + color1 + color2 + color3) * 0.25;
    float coc = min(min(min(coc0, coc1), coc2), coc3);

    frag_output = vec4(color.rgb, coc * 0.5 + 0.5);
}
