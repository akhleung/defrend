#version 420

in vec2 var_texcoord0;

#define NUM_SAMPLES 16
#define NUM_NOISE 4

uniform ssao_fp {
	mat4 mtx_proj;
	vec4 kernel[NUM_SAMPLES];
	vec4 noise[NUM_NOISE];
};

uniform sampler2D normal_sampler;
uniform sampler2D position_sampler;

out vec4 fragColor;

void main() {

	float radius    = 1.0;
  	float bias      = 0.25;
  	float magnitude = 1.1;
  	float contrast  = 1.0;

	vec3 frag_pos = texture(position_sampler, var_texcoord0).xyz; // view-space position of the rendered fragment
	vec3 frag_nrm = texture(normal_sampler, var_texcoord0).xyz * 2.0 - 1.0; // view-space normal of the rendered fragment

	float ao = NUM_SAMPLES;

	for (int i = 0; i < NUM_SAMPLES; ++i) {

		vec3 samp_pos = frag_pos + kernel[i].xyz * radius; // view-space position of the sample near the fragment
		vec4 samp_uv = mtx_proj * vec4(samp_pos, 1.0); // screen-space position of the aforementioned sample
		samp_uv = (samp_uv / samp_uv.w) * 0.5 + 0.5; // perspective divide; scale and bias [-1, 1] -> [0, 1]
		vec3 occluder_pos = texture(position_sampler, samp_uv.xy).xyz; // view-space position of the rendered fragment at the sample position (hypothetical occluder)
		
		// vec3 occluder_diff = occluder_pos - frag_pos;
		// float occluder_dist = length(occluder_diff);
		// if (occluder_dist > radius) continue;

		// float occluder_depth = occluder_pos.z;
		// float sample_depth = samp_pos.z;
		// float check = smoothstep(0.0, 1.0, radius / abs(frag_pos.z - occluder_depth));
		// ao -= (occluder_depth >= samp_pos.z + bias ? 1.0 : 0.0) * check;
		
		vec3 frag_to_occl = occluder_pos - frag_pos;
		float l = length(frag_to_occl);
		float o = max(0.0, dot(frag_nrm, normalize(frag_to_occl)) - bias) / (1.0 + l);
		ao -= o * contrast;
	}

	ao /= NUM_SAMPLES;

	fragColor = vec4(ao);
}
