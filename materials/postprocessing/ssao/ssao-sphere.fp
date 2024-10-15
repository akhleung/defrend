#version 420

in vec2 var_texcoord0;

#define NUM_SAMPLES 16
#define NUM_NOISE 4

uniform ssao_fp {
	mat4 mtx_proj;
	vec4 resolution;
	vec4 kernel[NUM_SAMPLES];
	vec4 noise[NUM_NOISE];
};

uniform sampler2D color_sampler;
uniform sampler2D normal_sampler;
uniform sampler2D position_sampler;

out vec4 fragColor;

void main() {

	float radius    = 0.2;
  	float bias      = 0.001;
  	float magnitude = 1.1;
  	float contrast  = 1.0;

	fragColor = vec4(1.0);

	vec3 frag_pos = texture(position_sampler, var_texcoord0).xyz; // view-space position of the rendered fragment
	vec3 frag_nrm = texture(normal_sampler, var_texcoord0).xyz; // view-space normal of the rendered fragment

	float r = radius / frag_pos.z;
	float ao = NUM_SAMPLES;

	float angle = (int(gl_FragCoord.x + 0.5) % 16) * 6.28;

	for (int i = 0; i < NUM_SAMPLES; ++i) {

		vec3 samp_pos = frag_pos + kernel[i].xyz * radius; // view-space position of the sample near the fragment
		vec4 samp_uv = mtx_proj * vec4(samp_pos, 1.0); // screen-space position of the aforementioned sample
		samp_uv.xy /= samp_uv.w;
		samp_uv.xy = samp_uv.xy * 0.5 + 0.5;
		vec3 occluder_pos = texture(position_sampler, samp_uv.xy).xyz; // view-space position of the rendered fragment at the sample position (hypothetical occluder)
		
		vec3 occluder_diff = occluder_pos - frag_pos;
		float occluder_dist = length(occluder_diff);
		if (occluder_dist > radius) continue;

		float occluder_depth = occluder_pos.z;
		float sample_depth = samp_pos.z;
		float check = smoothstep(0.0, 1.0, radius / abs(frag_pos.z - occluder_depth));
		ao -= (occluder_depth >= samp_pos.z + bias ? 1.0 : 0.0) * check;
		
		// vec3 frag_to_occl = occluder_pos - frag_pos;
		// float d = length(frag_to_occl);
		// frag_to_occl = normalize(frag_to_occl);
		// float o = max(0.0, dot(frag_nrm, frag_to_occl)) * (1.0 / (1.0 + d));
		// ao -= o * contrast;
	}

	ao /= NUM_SAMPLES;

	fragColor = vec4(vec3(ao), 1.0);
}
