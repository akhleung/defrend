#version 420 core

in vec2 var_texcoord0;

uniform sampler2D normal_sampler;
uniform sampler2D position_sampler;

uniform ssao_fp {
    vec4 params1;
    vec4 params2;
};

int   samples      = int(params1.x);
float intensity    = params1.y;
float bias         = params1.z;
float radius       = params1.w;
float min_distance = params2.x * 0.5;
float max_distance = params2.x * 2.0;
float attenuation  = params2.y;

const float goldenAngle = 2.4;

out vec4 frag_color;

float hash(vec2 v) {
    return fract(sin(dot(v, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {

	vec3  origin   = texture(position_sampler, var_texcoord0).xyz;
  	vec3  normal   = texture(normal_sampler, var_texcoord0).xyz * 2.0 - 1.0;
    float rotation = hash(var_texcoord0) * 6.28;
    float rStep    = radius / abs(origin.z) / samples;
    float ao       = 0.0;

    for (int i = 0; i < samples; i++) {
        vec2 spiralUV = vec2(cos(rotation), sin(rotation)) * rStep * i;
		vec3 offset = texture(position_sampler, var_texcoord0 + spiralUV).xyz;

        vec3 diff = offset - origin;
        float fadeout = 1.0 - smoothstep(min_distance, max_distance, length(diff) * attenuation);
        float incidence = smoothstep(bias, 1.0, dot(normal, normalize(diff)));
        ao += incidence * fadeout;

        rotation += goldenAngle;
    }

	frag_color = vec4(1.0 - ao / samples * intensity);
}
