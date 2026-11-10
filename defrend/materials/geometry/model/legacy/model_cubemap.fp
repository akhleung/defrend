#version 420 core

in vec3 var_frag_pos;

uniform shadow_fp {
	vec4 radius;
};

void main() {
	// write linear depth for cubemap/omnidirectional shadow mapping
	gl_FragDepth = length(var_frag_pos) / radius.x;
}
