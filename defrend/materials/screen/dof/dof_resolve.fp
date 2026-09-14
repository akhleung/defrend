#version 420

in vec2 var_texcoord0;

uniform sampler2D focused_sampler;
uniform sampler2D blurred_sampler;

layout(location = 0) out vec4 frag_output;

void main() {
	vec4 focused_frag = texture(focused_sampler, var_texcoord0);
	vec4 blurred_frag = texture(blurred_sampler, var_texcoord0);
	frag_output = vec4(mix(focused_frag.rgb, blurred_frag.rgb, blurred_frag.a), 1.0);
	// frag_output = blurred_frag;
}
