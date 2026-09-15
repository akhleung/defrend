#version 420 core

in vec2 var_texcoord0;

uniform sampler2D downsampled_sampler;

uniform pack_coc_fp {
	vec4 params;
	vec4 frustum_terms;
};

layout(location = 0) out float frag_output;

void main() {
	float max_near_coc = 0;
	for (int y = -2; y < 2; ++y) {
		for (int x = -2; x < 2; ++x) {
			// float sample_coc = textureOffset(downsampled_sampler, var_texcoord0, ivec2(x, y)).a * 2.0 - 1.0;
			float sample_coc = texelFetch(downsampled_sampler, ivec2(gl_FragCoord.xy) + ivec2(x, y), 0).a * 2.0 - 1.0;
			max_near_coc = max(max_near_coc, sample_coc);
		}
	}
	frag_output = max_near_coc;
}
