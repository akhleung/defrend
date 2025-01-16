#version 420 core

in vec3 var_center;
in vec4 var_color;
in vec4 var_radii;

uniform sampler2D diffuse_sampler;
uniform sampler2D position_sampler;
uniform sampler2D normal_sampler;
uniform sampler2D ssao_sampler;

uniform point_light_fp {
	vec4 resolution;
};

out vec4 frag_color;

float specular(vec3 viewdir, vec3 lightdir, vec3 norm, float shiny) {
    vec3 R = reflect(-lightdir, norm);
    return pow(max(dot(R, viewdir), 0.0), shiny);
}

float attenuation(float d, float r_inner, float r_outer) {
    float falloff = 1.0 - smoothstep(r_inner, r_outer, d);
    return falloff * falloff;
}

void main() {
	vec2 texcoord = gl_FragCoord.xy / resolution.xy;
	vec4 position_sample = texture(position_sampler, texcoord);
	vec4 normal_sample = texture(normal_sampler, texcoord);
	float ao = texture(ssao_sampler, texcoord).a;
	vec3 geom_pos = position_sample.xyz;
	vec3 to_light = var_center - geom_pos;
	// if (length(to_light) > var_radii.y) discard;
	vec3 to_view = -geom_pos;
	vec3 normal = normal_sample.xyz * 2.0 - 1.0;
	vec3 to_light_normalized = normalize(to_light);
	float diff = max(dot(normal, to_light_normalized), 0.0);
	float spec = specular(normalize(to_view), to_light_normalized, normal, position_sample.w);
	float attn = attenuation(length(to_light), var_radii.x, var_radii.y);
	vec4 mat_diff = texture(diffuse_sampler, texcoord);
	vec4 mat_spec = vec4(normal_sample.w, normal_sample.w, normal_sample.w, 1.0);
	frag_color = (mat_diff * diff * ao + mat_spec * spec) * var_color * attn;
}
