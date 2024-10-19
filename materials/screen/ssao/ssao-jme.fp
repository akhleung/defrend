#version 420

in vec2 var_texcoord0;

#define NUM_SAMPLES 16
#define NUM_NOISE 4

#define RADIUS 0.1
#define BIAS 0.05
#define INTENSITY 1.1
#define SCALE 0.05

uniform ssao_fp {
	mat4 mtx_proj;
	vec4 resolution;
	vec4 kernel[NUM_SAMPLES];
	vec4 noise[NUM_NOISE];
};

uniform sampler2D color_sampler;
uniform sampler2D normal_sampler;
uniform sampler2D position_sampler;

float doAmbientOcclusion(in vec2 tc, in vec3 pos, in vec3 norm){
	vec3 diff = texture(position_sampler, tc).xyz - pos;	
	vec3 v = normalize(diff);
	float d = length(diff) * SCALE;
	return max(0.0, dot(norm, v) - BIAS) * 1.0/(1.0 + d) * INTENSITY;
}

out vec4 frag_out;

void main() {

	vec3 position = texture(position_sampler, var_texcoord0).xyz;
  	vec3 normal   = texture(normal_sampler, var_texcoord0).xyz;

	int  noiseS = int(sqrt(NUM_NOISE));
  	int  noiseX = int(gl_FragCoord.x - 0.5) % noiseS;
  	int  noiseY = int(gl_FragCoord.y - 0.5) % noiseS;
  	vec3 rand = noise[noiseX + (noiseY * noiseS)].xyz;

	float ao = 0.0;
	float rad = RADIUS / position.z;

	for (int j = 0; j < NUM_SAMPLES; ++j) {
		vec2 coord1 = reflect(vec2(kernel[j]), vec2(rand)) * vec2(rad);
		vec2 coord2 = vec2(coord1.x * 0.707 - coord1.y * 0.707, coord1.x * 0.707 + coord1.y * 0.707);

		ao += doAmbientOcclusion(var_texcoord0 + coord1 * 0.25, position, normal);
		ao += doAmbientOcclusion(var_texcoord0 + coord2 * 0.5, position, normal);
		ao += doAmbientOcclusion(var_texcoord0 + coord1 * 0.75, position, normal);
		ao += doAmbientOcclusion(var_texcoord0 + coord2 * 1.0, position, normal);		
	}
	ao /= float(NUM_SAMPLES) * 4.0;
	float result = 1.0 - ao;
	frag_out = vec4(result, result, result, 1.0);
}
