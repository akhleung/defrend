#version 420 core

in vec2 var_texcoord0;

uniform sampler2D depth_buffer;
uniform sampler2D normal_sampler;

uniform ssao_fp {
    mat4 mtx_proj_inv;
    vec4 params1;
    vec4 params2;
};

int samples = int(params1.x);
float intensity = params1.y;
float bias_angle = params1.z;
float min_distance = params2.x * 0.5;
float max_distance = params2.x * 2.0;
float attenuation = params2.y;
float radius = params2.w;

out vec4 frag_color;

const vec3 mod3 = vec3(.1031, .11369, .13787);
const float goldenAngle = 2.4;

highp vec3 viewPosFromDepth(highp float depth, vec2 uv) {
    highp vec4 clipSpacePos = vec4(uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    highp vec4 viewSpacePos = mtx_proj_inv * clipSpacePos;
    viewSpacePos /= viewSpacePos.w;
    return viewSpacePos.xyz;
}

float hash12(vec2 p) {
	vec3 p3  = fract(vec3(p.xyx) * mod3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float calculateOcclusion(highp vec3 op, highp vec3 p, in vec3 n, float depth) {
    vec3 diff = op - p;
    float l = length(diff);
    float ao = max(0.0, dot(n, normalize(diff)) - (bias_angle + bias_angle * depth * 2)) /*  (1.0 + l * attenuation)*/;
    ao *= 1.0 - smoothstep(min_distance, max_distance, l); // increasing the upper bound seems to allow AO to persist at very oblique angles
    return ao;
}

float spiralAO(highp vec3 p, vec3 n, float depth) {
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
        vec2 offset_uv = var_texcoord0 + spiralUV * radiusInc;
        float depthv = texture(depth_buffer, offset_uv).r;
        highp vec3 op = viewPosFromDepth(depthv, offset_uv);
        ao += calculateOcclusion(op, p, n, depth);
        rotatePhase += goldenAngle;
    }
    ao /= samples;
    return 1.0 - ao * intensity;
}

void main() {
    float depthv = texture(depth_buffer, var_texcoord0).r;
    if (depthv == 1) {
        frag_color = vec4(1);
        return;
    }

    highp vec3 position = viewPosFromDepth(depthv, var_texcoord0);
  	vec3 normal   = texture(normal_sampler, var_texcoord0).xyz * 2.0 - 1.0;

	float ao = spiralAO(position, normal, depthv);
    ao *= ao;
	frag_color = vec4(ao, ao, ao, ao);
}