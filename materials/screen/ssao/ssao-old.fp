#version 420

in vec2 var_texcoord0;

#define NUM_SAMPLES 64
#define NUM_NOISE 16

uniform ssao_fp {
    vec4 params1;
    vec4 params2;
	mat4 mtx_proj;
	vec4 kernel[NUM_SAMPLES];
	vec4 noise[NUM_NOISE];
};

uniform sampler2D normal_sampler;
uniform sampler2D position_sampler;

out vec4 frag_out;

void main() {

	frag_out = vec4(1);

	vec3 position = texture(position_sampler, var_texcoord0).xyz;
  	vec3 normal   = texture(normal_sampler, var_texcoord0).xyz * 2.0 - 1.0;

	int u = int(gl_FragCoord.x - 0.5) % 4;
	int v = int(gl_FragCoord.y - 0.5) % 4;
	vec3 random = noise[u * 4 + v].xyz;
	random = noise[int(gl_FragCoord.x - 0.5) % NUM_NOISE].xyz;

 	vec3 tangent  = normalize(random - normal * dot(random, normal));
  	vec3 binormal = cross(normal, tangent);
  	mat3 tbn      = mat3(tangent, binormal, normal);

	float bias = 0.0;
	float radius = 0.8;
	float occlusion = 0.0;

  	for (int i = 0; i < NUM_SAMPLES; ++i) {
		// get sample position:
		vec3 samp = tbn * kernel[i].xyz;
		samp = samp * radius + position;

		// project samp position:
		vec4 offset = vec4(samp, 1.0);
		offset = mtx_proj * offset;
		offset.xyz /= offset.w;
		offset.xy = offset.xy * 0.5 + 0.5;

		// get samp depth:
		float depth = texture(position_sampler, offset.xy).z;
		
		// range check & accumulate:
		float check = smoothstep(0.0, 1.0, radius / abs(position.z - depth));
		occlusion += (depth >= samp.z + bias ? 1.0 : 0.0) * check;
	}

	occlusion = 1.0 - (occlusion / NUM_SAMPLES);
	
	frag_out = vec4(occlusion); 

}
