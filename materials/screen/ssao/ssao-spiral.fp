#version 420 core

in vec2 var_texcoord0;

uniform sampler2D normal_sampler;
uniform sampler2D position_sampler;

uniform ssao_fp {
    vec4 params1;
    vec4 params2;
};

int samples = int(params1.x);
float intensity = params1.y;
float bias = params1.z;
float radius = params1.w;
float min_distance = params2.x * 0.5;
float max_distance = params2.x * 2.0;
float attenuation = params2.y;

out vec4 frag_color;

const vec3 mod3 = vec3(.1031, .11369, .13787);
const float goldenAngle = 2.4;

float hash12(vec2 p) {
	vec3 p3  = fract(vec3(p.xyx) * mod3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float calculateOcclusion(in vec3 op, in vec3 p, in vec3 cnorm) {
    vec3 diff = op - p;
    float l = length(diff);
    float ao = max(0.0, dot(cnorm, normalize(diff)) - bias) / (1.0 + l * attenuation);
    ao *= 1.0 - smoothstep(min_distance, max_distance, l); // increasing the upper bound seems to allow AO to persist at very oblique angles
    return ao;
}

float spiralAO(vec3 p, vec3 n) {
    float rad = radius / abs(p.z);
    float ao = 0.0;
    float radiusInc = 0.0;

    float rotatePhase = hash12(var_texcoord0 * 100.0) * 6.28;
    float rStep = rad / samples;
    vec2 spiralUV;

    for (int i = 0; i < samples; i++) {
        spiralUV.x = sin(rotatePhase);
        spiralUV.y = cos(rotatePhase);
        radiusInc += rStep;
		vec3 offset_pos = texture(position_sampler, var_texcoord0 + spiralUV * radiusInc).xyz;
        ao += calculateOcclusion(offset_pos, p, n);
        rotatePhase += goldenAngle;
    }
    ao /= samples;
    return 1.0 - ao * intensity;
}

void main() {

	vec3 position = texture(position_sampler, var_texcoord0).xyz;
  	vec3 normal   = texture(normal_sampler, var_texcoord0).xyz * 2.0 - 1.0;

	float ao = spiralAO(position, normal);
    // ao *= ao;
	frag_color = vec4(ao, ao, ao, 1.0);
}
