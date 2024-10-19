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
uniform sampler2D position_sampler;
uniform sampler2D normal_sampler;

out vec4 frag_out;

void main() {

	float radius    = 1;
  	float bias      = 0.01;
  	float magnitude = 1.5;
  	float contrast  = 1.5;

	// frag_out = vec4(1.0);

	vec3 position = texture(position_sampler, var_texcoord0).xyz;
  	vec3 normal   = texture(normal_sampler, var_texcoord0).xyz;

   	int  noiseS = int(sqrt(NUM_NOISE));
    int  noiseX = int(gl_FragCoord.x - 0.5) % noiseS;
  	int  noiseY = int(gl_FragCoord.y - 0.5) % noiseS;
  	vec3 random = noise[noiseX + (noiseY * noiseS)].xyz;

 	vec3 tangent  = normalize(random - normal * dot(random, normal));
  	vec3 binormal = cross(normal, tangent);
  	mat3 tbn      = mat3(tangent, binormal, normal);

	float occlusion = NUM_SAMPLES;

  	for (int i = 0; i < NUM_SAMPLES; ++i) {
    	vec3 samplePosition = tbn * kernel[i].xyz;
        samplePosition = position + samplePosition * radius;

    	vec4 offsetUV      = vec4(samplePosition, 1.0);
        offsetUV      = mtx_proj * offsetUV;
        offsetUV.xyz /= offsetUV.w;
        offsetUV.xy   = offsetUV.xy * 0.5 + 0.5;

    	// Config.prc
    	// gl-coordinate-system  default
    	// textures-auto-power-2 1
    	// textures-power-2      down

    	vec4 offsetPosition = texture(position_sampler, offsetUV.xy);

    	float occluded = 0;
    	if (samplePosition.z + bias <= offsetPosition.z) {
			occluded = 0;
		} else {
			occluded = 1;
		}

    	float intensity = smoothstep(0, 1, radius / abs(position.z - offsetPosition.z));
    	occluded  *= intensity;
    	occlusion -= occluded;
	}

	occlusion /= NUM_SAMPLES;
	occlusion  = pow(occlusion, magnitude);
	occlusion  = contrast * (occlusion - 0.5) + 0.5;

	frag_out = vec4(vec3(occlusion), 1.0);
}
