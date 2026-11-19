#version 420 core

in vec3 var_frag_pos;

uniform shadow_fp {
	vec4 radius;
};

layout(location = 0) out float frag_out;

void main() {
	// write linear distance to the light origin for cubemap/omnidirectional shadow mapping
	frag_out = length(var_frag_pos) / radius.x;
}
