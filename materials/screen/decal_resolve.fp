#version 420 core

in vec2 var_texcoord0;

uniform sampler2D decal_diff_sampler;
uniform sampler2D decal_norm_sampler;
uniform sampler2D decal_spec_glow_sampler;

layout(location = 0) out vec4 diff_out;
layout(location = 1) out vec4 norm_out;
layout(location = 2) out vec4 spec_glow_out;

void main() {
	diff_out = texture(decal_diff_sampler, var_texcoord0);
	norm_out = texture(decal_norm_sampler, var_texcoord0);
	spec_glow_out = texture(decal_spec_glow_sampler, var_texcoord0);
}
