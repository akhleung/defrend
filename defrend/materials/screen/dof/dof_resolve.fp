#version 420
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/dof_functions.glsl"

in vec2 var_texcoord0;

uniform sampler2D focused_sampler;
uniform sampler2D blurred_sampler;

uniform dof_resolve_fp {
	vec4 params;
};

int blur_samples = int(params.x);
float blur_radius = params.y;
float focused_coc_threshold = params.z;
float coc_visualization = params.w;

layout(location = 0) out vec4 frag_output;

void main() {
	vec4 focused_frag	= texture(focused_sampler, var_texcoord0);
	vec4 blurred_frag	= texture(blurred_sampler, var_texcoord0);

	float original_coc	= focused_frag.a * 2.0 - 1.0;
	float dilated_coc	= blurred_frag.a * 2.0 - 1.0;
	float coc			= dilated_coc;

	if (abs(original_coc) > abs(dilated_coc)) {
		// unfocused area somehow became more focused, which shouldn't happen
		coc = original_coc;
	} else if (original_coc > dilated_coc) {
		// something further back bled over something in front, which shouldn't happen
		coc = original_coc;
	}

	frag_output = vec4(mix(focused_frag, blurred_frag, abs(coc)).rgb, 1.0);

	if (coc_visualization > 0) {
		frag_output = visualize_coc(coc_visualization <= 1 ? original_coc : coc_visualization <= 2 ? dilated_coc : coc);
	}
}
