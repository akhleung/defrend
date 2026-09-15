#version 420

in vec2 var_texcoord0;

uniform sampler2D focused_sampler;
uniform sampler2D downsampled_sampler;
uniform sampler2D dilated_coc_sampler;
uniform sampler2D blurred_near_sampler;
uniform sampler2D blurred_far_sampler;

layout(location = 0) out vec4 frag_output;

void main() {
	vec4 focused_frag = texture(focused_sampler, var_texcoord0);
	float full_coc = texture(downsampled_sampler, var_texcoord0).a * 2.0 - 1.0;

	vec4 blurred_near_frag = texture(blurred_near_sampler, var_texcoord0);
	vec4 blurred_far_frag = texture(blurred_far_sampler, var_texcoord0);

	float dilated_coc = texture(dilated_coc_sampler, var_texcoord0).r;

	float far_alpha = clamp(-full_coc, 0, 1);
	vec3 composite = mix(focused_frag.rgb, blurred_far_frag.rgb, far_alpha);

	float near_alpha = clamp(dilated_coc, 0, 1);
	composite = mix(composite, blurred_near_frag.rgb, near_alpha);
	frag_output = vec4(composite, 1.0);
	// frag_output = vec4(mix(focused_frag.rgb, blurred_frag.rgb, blurred_frag.a), 1.0);
	// frag_output = blurred_frag;
}
