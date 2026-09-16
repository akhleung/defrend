#version 420 core

in vec2 var_texcoord0;

uniform sampler2D downsampled_sampler;

layout(location = 0) out float frag_output;

void main() {
	float max_near_coc = 0;

	// max_near_coc = max(max_near_coc, textureOffset(downsampled_sampler, var_texcoord0, ivec2(-2, -2)).a * 2.0 - 1.0);
	max_near_coc = max(max_near_coc, textureOffset(downsampled_sampler, var_texcoord0, ivec2(-1, -2)).a * 2.0 - 1.0);
	max_near_coc = max(max_near_coc, textureOffset(downsampled_sampler, var_texcoord0, ivec2(0, -2)).a * 2.0 - 1.0);
	max_near_coc = max(max_near_coc, textureOffset(downsampled_sampler, var_texcoord0, ivec2(1, -2)).a * 2.0 - 1.0);
	// max_near_coc = max(max_near_coc, textureOffset(downsampled_sampler, var_texcoord0, ivec2(2, -2)).a * 2.0 - 1.0);

	max_near_coc = max(max_near_coc, textureOffset(downsampled_sampler, var_texcoord0, ivec2(-2, -1)).a * 2.0 - 1.0);
	max_near_coc = max(max_near_coc, textureOffset(downsampled_sampler, var_texcoord0, ivec2(-1, -1)).a * 2.0 - 1.0);
	max_near_coc = max(max_near_coc, textureOffset(downsampled_sampler, var_texcoord0, ivec2(0, -1)).a * 2.0 - 1.0);
	max_near_coc = max(max_near_coc, textureOffset(downsampled_sampler, var_texcoord0, ivec2(1, -1)).a * 2.0 - 1.0);
	max_near_coc = max(max_near_coc, textureOffset(downsampled_sampler, var_texcoord0, ivec2(2, -1)).a * 2.0 - 1.0);

	max_near_coc = max(max_near_coc, textureOffset(downsampled_sampler, var_texcoord0, ivec2(-2, 0)).a * 2.0 - 1.0);
	max_near_coc = max(max_near_coc, textureOffset(downsampled_sampler, var_texcoord0, ivec2(-1, 0)).a * 2.0 - 1.0);
	max_near_coc = max(max_near_coc, textureOffset(downsampled_sampler, var_texcoord0, ivec2(0, 0)).a * 2.0 - 1.0);
	max_near_coc = max(max_near_coc, textureOffset(downsampled_sampler, var_texcoord0, ivec2(1, 0)).a * 2.0 - 1.0);
	max_near_coc = max(max_near_coc, textureOffset(downsampled_sampler, var_texcoord0, ivec2(2, 0)).a * 2.0 - 1.0);

	max_near_coc = max(max_near_coc, textureOffset(downsampled_sampler, var_texcoord0, ivec2(-2, 1)).a * 2.0 - 1.0);
	max_near_coc = max(max_near_coc, textureOffset(downsampled_sampler, var_texcoord0, ivec2(-1, 1)).a * 2.0 - 1.0);
	max_near_coc = max(max_near_coc, textureOffset(downsampled_sampler, var_texcoord0, ivec2(0, 1)).a * 2.0 - 1.0);
	max_near_coc = max(max_near_coc, textureOffset(downsampled_sampler, var_texcoord0, ivec2(1, 1)).a * 2.0 - 1.0);
	max_near_coc = max(max_near_coc, textureOffset(downsampled_sampler, var_texcoord0, ivec2(2, 1)).a * 2.0 - 1.0);

	// max_near_coc = max(max_near_coc, textureOffset(downsampled_sampler, var_texcoord0, ivec2(-2, 2)).a * 2.0 - 1.0);
	max_near_coc = max(max_near_coc, textureOffset(downsampled_sampler, var_texcoord0, ivec2(-1, 2)).a * 2.0 - 1.0);
	max_near_coc = max(max_near_coc, textureOffset(downsampled_sampler, var_texcoord0, ivec2(0, 2)).a * 2.0 - 1.0);
	max_near_coc = max(max_near_coc, textureOffset(downsampled_sampler, var_texcoord0, ivec2(1, 2)).a * 2.0 - 1.0);
	// max_near_coc = max(max_near_coc, textureOffset(downsampled_sampler, var_texcoord0, ivec2(2, 2)).a * 2.0 - 1.0);

	frag_output = max_near_coc;
}
