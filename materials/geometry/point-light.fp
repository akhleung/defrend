#version 420

in vec3 var_center;
in vec4 var_color;
in vec4 var_radii;

uniform sampler2D depth_buffer;
uniform sampler2D normal_sampler;

uniform point_light_fp {
	vec4 resolution;
    vec4 frustum_corner;
    vec4 frustum_terms;
};

out vec4 diff_out;
out vec4 spec_out;

float linearizeDepth(float d) {
    float zNdc  = 2.0 * d - 1.0;
    return 2.0 * frustum_terms.x / (frustum_terms.y - zNdc * (frustum_terms.z));
}

vec3 viewPosFromLinearDepth(float z, vec2 uv) {
    vec2  uvNdc = 2.0 * uv - 1.0;
    vec2  xyFar = frustum_corner.xy * uvNdc;
    float zNorm = z / frustum_corner.z;
    return vec3(xyFar * zNorm, z);
}

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
    float depth = texture(depth_buffer, texcoord).r;
	float z = linearizeDepth(depth);
	vec3 geom_pos = viewPosFromLinearDepth(z, texcoord);
	vec4 normal_sample = texture(normal_sampler, texcoord);
	vec3 to_light = var_center - geom_pos;
	float d = length(to_light);
	if (d > var_radii.y) discard;
	vec3 to_view = -geom_pos;
	vec3 normal = normal_sample.xyz * 2.0 - 1.0;
	vec3 to_light_normalized = normalize(to_light);
	float diff = max(dot(normal, to_light_normalized), 0.0);
	float spec = specular(normalize(to_view), to_light_normalized, normal, 0); // TODO: find someplace else to put the specular power
	float attn = attenuation(d, var_radii.x, var_radii.y);
	diff_out = var_color * diff * attn;
	spec_out = var_color * spec * attn;
}
