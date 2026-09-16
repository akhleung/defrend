#version 420

in vec2 var_texcoord0;

uniform sampler2D focused_sampler;
uniform sampler2D blurred_sampler;

layout(location = 0) out vec4 frag_output;

void main() {
	vec4 focused_frag = texture(focused_sampler, var_texcoord0);
	vec4 blurred_frag = texture(blurred_sampler, var_texcoord0);

	float orig_coc = focused_frag.a * 2.0 - 1.0;
	float blurred_coc = blurred_frag.a * 2.0 - 1.0;

	float coc = blurred_coc;

	if (var_texcoord0.y < 0.5) {
		if (coc < 0) {
			frag_output = vec4(abs(coc), 0, 0, 1);
		} else {
			frag_output = vec4(0, 0, abs(coc), 1);
		}
	} else {
		frag_output = focused_frag;
	}

	frag_output = vec4(mix(focused_frag, blurred_frag, abs(coc)).rgb, 1.0);

	// frag_output = vec4(mix(focused_frag.rgb, blurred_frag.rgb, abs(blurred_frag.a * 2 - 1)), 1.0);
	// float coc = blurred_frag.a * 2.0 - 1.0;

	// if (coc < 0) {
	// 	frag_output = vec4(abs(coc), 0, 0, 1);
	// } else {
	// 	frag_output = vec4(0, 0, coc, 1);
	// }

	// if (var_texcoord0.y > 0.5) {
	// 	frag_output = vec4(focused_frag.rgb, 1.0);
	// }
	// frag_output = blurred_frag;
}
