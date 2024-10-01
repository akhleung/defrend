#version 420 core

#define MAX_LIGHTS 16

in vec2 var_texcoord0;

uniform sampler2D diffuse_sampler;
uniform sampler2D position_sampler;
uniform sampler2D normal_sampler;
uniform sampler2D ssao_sampler;
// uniform sampler2D depth_sampler;

uniform screen_fp {
    mat4 mtx_view;
    
    vec4 ambient_color;

    vec4 sun_color;
    vec4 sun_direction;
    
    vec4 num_lights;
    vec4 light_positions[MAX_LIGHTS];
    vec4 light_radii[MAX_LIGHTS];
    vec4 light_colors[MAX_LIGHTS];
};

out vec4 frag_color;

vec3 light_direction(vec3 frag_pos, vec3 light_pos) {
    return normalize(light_pos - frag_pos);
}

float diffuse(vec3 light_dir, vec3 normal_sample) {
    return max(dot(normal_sample, light_dir), 0.0);
}

float attenuation(vec3 frag_pos, vec3 light_pos, vec4 light_radii) {
    float r_inner = light_radii.x;
    float r_outer = light_radii.y;
    float d = distance(frag_pos, light_pos);
    // float falloff = clamp((r_outer - d) / (r_outer - r_inner), 0.0, 1.0);
    float falloff = 1.0 - smoothstep(r_inner, r_outer, d);
    return falloff * falloff;
}

// float specular(vec3 view_dir, vec3 light_dir, vec3 normal_sample) {
//     vec3 r = reflect(-light_dir, normal_sample); // TODO: fix this
//     return max(dot(r, normal_sample), 0.0);
// }

float specular(vec3 viewdir, vec3 lightdir, vec3 norm, float shiny){
    vec3 H = normalize(viewdir + lightdir);
    float HdotN = max(0.0, dot(H, norm));
    return pow(HdotN, shiny);
}

void main() {

    vec4 position_sample = texture(position_sampler, var_texcoord0);
    vec4 normal_sample = texture(normal_sampler, var_texcoord0);

    vec3 var_frag_pos = position_sample.xyz;
    vec3 view_dir = normalize(-var_frag_pos);

    vec4 mat_spec = vec4(normal_sample.w, normal_sample.w, normal_sample.w, 1.0);
    float spec_exp = position_sample.w;

    vec4 mat_diff = texture(diffuse_sampler, var_texcoord0);
    vec3 normal = normal_sample.xyz;

	frag_color = texture(ssao_sampler, var_texcoord0);

    float ao = texture(ssao_sampler, var_texcoord0).x;
    float blur = texture(ssao_sampler, var_texcoord0).y;
    ao = blur;

    vec4 color = ambient_color * mat_diff * ao * ao;

    // directional (i.e., sun) light
    vec3 sun_dir = mat3(mtx_view) * normalize(-sun_direction.xyz);
    float sun_spec = specular(view_dir, sun_dir, normal, spec_exp);
    float sun_diff = diffuse(sun_dir, normal) * ao * ao;
    color += (sun_diff * mat_diff + sun_spec * mat_spec) * sun_color;

    for (int i = 0; i < num_lights.x; ++i) {
        vec4 light_pos = mtx_view * light_positions[i];
        vec3 light_dir = light_direction(var_frag_pos, light_pos.xyz);
        float spec = specular(view_dir, light_dir, normal, spec_exp);
        float diff = diffuse(light_dir, normal);
        float attn = attenuation(var_frag_pos, light_pos.xyz, light_radii[i]);
        color += (diff * mat_diff + spec * mat_spec) * light_colors[i] * attn;
    }

    color.a = mat_diff.a;
    // color = texture(ssao_sampler, var_texcoord0);
    // color = vec4(blur, blur, blur, 1.0);
    // color = texture(depth_sampler, var_texcoord0);
    frag_color = clamp(color, 0.0, 1.0);
}
