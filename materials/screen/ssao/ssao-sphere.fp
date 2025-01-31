#version 420

in vec2 var_texcoord0;

#define NUM_SAMPLES 32

uniform ssao_fp {
	mat4 mtx_proj;
	mat4 mtx_proj_inv;
	vec4 kernel[NUM_SAMPLES];
	vec4 frustum_corner_view;
};

uniform highp sampler2D depth_buffer;
uniform sampler2D normal_sampler;
uniform sampler2D position_sampler;

out vec4 fragColor;

vec3 viewPosFromLinearDepth(float z, vec2 uv) {
    return vec3((2 * uv - 1) * frustum_corner_view.xy * (z / frustum_corner_view.z), z);
}

const vec3 mod3 = vec3(.1031, .11369, .13787);

float hash12(vec2 p) {
	vec3 p3  = fract(vec3(p.xyx) * mod3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

void main() {

	highp float depth = texture(position_sampler, var_texcoord0).z;
	if (depth <= frustum_corner_view.z) {
		fragColor = vec4(1);
		return;
	}

	float radius    = 1.0;
  	float bias      = 0.25;

	vec3 frag_pos = viewPosFromLinearDepth(depth, var_texcoord0);
	vec3 frag_nrm = texture(normal_sampler, var_texcoord0).xyz * 2.0 - 1.0; // view-space normal of the rendered fragment

	float ao = 0;

    float rotatePhase = hash12(var_texcoord0 * 100.0) * 6.28;
	vec3 noise_vec = vec3(sin(rotatePhase), cos(rotatePhase), sin(rotatePhase));

	for (int i = 0; i < NUM_SAMPLES; ++i) {

		highp vec3 displacement = kernel[i].xyz * radius;
		displacement = reflect(displacement, noise_vec);
		highp float incidence = dot(frag_nrm, normalize(displacement)); // check if sample is inside the geometry
		highp vec3 samp_pos = incidence < 0 ? frag_pos - displacement : frag_pos + displacement;
		highp vec4 samp_uv = mtx_proj * vec4(samp_pos, 1.0); // clip-space position of the aforementioned sample
		samp_uv = (samp_uv / samp_uv.w) * 0.5 + 0.5; // perspective divide; scale and bias [-1, 1] -> [0, 1]
		highp vec3 occluder_pos = viewPosFromLinearDepth(texture(position_sampler, samp_uv.xy).z, samp_uv.xy);
		
		// highp vec3 frag_to_occl = occluder_pos - frag_pos;
		// highp float l = length(frag_to_occl);
		if (length(occluder_pos - frag_pos) > radius) continue;
		
		// highp float attenuation = 1.0 - smoothstep(radius * 0.5, radius * 2, l);
		// incidence = smoothstep(bias, 1, dot(frag_nrm, normalize(frag_to_occl)));
		float occluded = occluder_pos.z >= samp_pos.z + bias ? 1.0 : 0.0;
		// occluded = 1;
		ao += occluded;

		// ao -= occluded * incidence * attenuation * 2.0;		
	}

	ao /= NUM_SAMPLES;

	fragColor = vec4(1 - ao);
}
