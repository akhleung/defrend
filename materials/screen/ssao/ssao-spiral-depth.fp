#version 420 core

in vec2 var_texcoord0;

uniform highp sampler2D depth_buffer;
uniform sampler2D position_sampler;
uniform sampler2D normal_sampler;

uniform ssao_fp {
    mat4 mtx_proj;
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

highp float linearizeDepth(highp float depth, highp vec2 projPlanes) {
	return -projPlanes.y / (depth + projPlanes.x);
}

highp vec3 positionFromDepth(highp float depth, highp vec2 uv, highp vec4 projMat) {
    if (depth == 1) return vec3(0);
	// Linearize depth -> in view space.
	highp float viewDepth = linearizeDepth(depth, projMat.zw);
	// Compute the x and y components in view space.
	highp vec2 ndcPos = 2.0 * uv - 1.0;
	return vec3(-ndcPos * viewDepth / projMat.xy , viewDepth);
}

vec3 positionfromViewSpaceZ(float viewDepth, vec2 uv, vec4 projMat) {
	highp vec2 ndcPos = 2.0 * uv - 1.0;
	return vec3(-ndcPos * viewDepth / projMat.xy , viewDepth);
}

float hash12(vec2 p) {
	vec3 p3  = fract(vec3(p.xyx) * mod3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

void main() {
    highp vec4 projParams = vec4(mtx_proj[0][0], mtx_proj[1][1], mtx_proj[2][2], mtx_proj[3][2]);
    highp vec3 position = positionFromDepth(texture(depth_buffer, var_texcoord0).r, var_texcoord0, projParams);
    position = positionfromViewSpaceZ(texture(position_sampler, var_texcoord0).z, var_texcoord0, projParams);
  	vec3 normal   = texture(normal_sampler, var_texcoord0).xyz * 2.0 - 1.0;

    float rad       = radius / abs(position.z);
    float radiusInc = 0.0;
    float ao        = 0.0;

    float rotatePhase = hash12(var_texcoord0 * 100.0) * 6.28;
    rotatePhase = 0;
    float rStep = rad / samples;
    vec2 spiralUV;

    for (int i = 0; i < samples; i++) {
        spiralUV.x = sin(rotatePhase);
        spiralUV.y = cos(rotatePhase);
        radiusInc += rStep;
        vec2 offsetUV = var_texcoord0 + spiralUV * radiusInc;
        vec3 offset_pos = positionFromDepth(texture(depth_buffer, offsetUV).r, offsetUV, projParams);
        offset_pos = positionfromViewSpaceZ(texture(position_sampler, offsetUV).z, offsetUV, projParams);

        vec3 diff = offset_pos - position;
        // float l = length(diff);
        // float fadeout = 1.0 - smoothstep(min_distance, max_distance, l * attenuation);
        float l2 = dot(diff, diff);
        float fadeout = 1.0 - smoothstep(min_distance * min_distance, max_distance * max_distance, l2 * attenuation);
        float incidence = smoothstep(bias, 1.0, dot(normal, normalize(diff)));
        ao += incidence * fadeout;

        rotatePhase += goldenAngle;
    }
    ao /= samples;
    ao = 1.0 - ao * intensity;

	frag_color = vec4(0, 0, 0, ao);
}
