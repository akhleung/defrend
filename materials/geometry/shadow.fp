#version 420 core

in vec3 var_frag_pos;
in vec3 var_normal;

uniform shadow_fp {
	vec4 sun_dir;
};

out float depth;

void main() {
	// float bias = (1.0 - dot(var_normal, sun_dir.xyz)) * 0.5;
	// depth = var_frag_pos.z - bias;
	// float cosTheta = clamp(1.0 - dot(var_normal, sun_dir.xyz), 0, 1);
	// float bias = 0.05*tan(acos(cosTheta)); // cosTheta is dot( n,l ), clamped between 0 and 1
	// bias = clamp(bias, 0, 0.05);
	// bias = 0;
	// float bias = (1.0 - dot(var_normal, sun_dir.xyz)) * 0.005;
	depth = gl_FragCoord.z;
}
