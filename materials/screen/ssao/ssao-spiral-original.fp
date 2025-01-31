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
float bias_angle = params1.z;
float min_distance = params2.x;
float max_distance = params2.y;
float attenuation = params2.z;
float radius = params2.w;

out vec4 frag_color;

const vec3 mod3 = vec3(.1031, .11369, .13787);
const float goldenAngle = 2.4;

float hash12(vec2 p) {
	vec3 p3  = fract(vec3(p.xyx) * mod3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

void main() {

	vec3 position = texture(position_sampler, var_texcoord0).xyz;
  	vec3 normal   = texture(normal_sampler, var_texcoord0).xyz * 2.0 - 1.0;

    float rad       = radius / abs(position.z);
    float radiusInc = 0.0;
    float ao        = 0.0;

    float rotatePhase = hash12(var_texcoord0 * 100.0) * 6.28;
    float rStep = rad / samples;
    vec2 spiralUV;

    for (int i = 0; i < samples; i++) {
        spiralUV.x = sin(rotatePhase);
        spiralUV.y = cos(rotatePhase);
        radiusInc += rStep;
		vec3 offset_pos = texture(position_sampler, var_texcoord0 + spiralUV * radiusInc).xyz;

        vec3 diff = offset_pos - position;
        float l = length(diff);
        float fadeout = 1.0 - smoothstep(min_distance, max_distance, l * attenuation);
        float incidence = smoothstep(bias_angle, 1.0, dot(normal, normalize(diff)));
        ao += incidence * fadeout;

        rotatePhase += goldenAngle;
    }
    ao /= samples;
    ao = 1.0 - ao * intensity;

	frag_color = vec4(ao);
}
