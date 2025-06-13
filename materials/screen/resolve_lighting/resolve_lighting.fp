#version 420 core
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/lighting_functions.glsl"

in vec2 var_texcoord0;

uniform sampler2D diffuse_sampler;
uniform sampler2D depth_buffer;
uniform sampler2D normal_sampler;
uniform sampler2D diff_light_sampler;
uniform sampler2D spec_light_sampler;
uniform sampler2D resolved_shadows;
uniform sampler2D shadow_depth;

uniform resolve_lighting_fp {
    mat4 mtx_view;
    vec4 frustum_corner;
    vec4 frustum_terms;

    vec4 fog_params;
    vec4 fog_color;
    vec4 ambient_color;
    vec4 directional_color;
    vec4 directional_to;
};

out vec4 frag_color;

float FOG_NEAR = fog_params.x;
float FOG_FAR = fog_params.y;

vec3 directional_from = normalize(mat3(mtx_view) * -directional_to.xyz);

void main() {

    vec4 normal_sample = texture(normal_sampler, var_texcoord0);
    vec4 point_diff = clamp(texture(diff_light_sampler, var_texcoord0), 0, 1);
    vec4 point_spec = clamp(texture(spec_light_sampler, var_texcoord0), 0, 1);

    float depth    = texture(depth_buffer, var_texcoord0).r;
    float z        = linearizeDepth(depth, frustum_terms.xyz);
    vec3 var_frag_pos = viewPosFromLinearDepth(z, var_texcoord0, frustum_corner.xyz);
    vec3 view_dir = normalize(-var_frag_pos);
    vec3 normal = normalize(normal_sample.xyz * 2.0 - 1.0); // rescale/bias [0, 1] -> [-1, 1]

    float shadow_d = texture(shadow_depth, var_texcoord0).r;
    float shadow = depth == shadow_d ? texture(resolved_shadows, var_texcoord0).r : 1;

    float shininess = normal_sample.w * 255;
    vec4 mat_diff = texture(diffuse_sampler, var_texcoord0);
    vec4 color = ambient_color * mat_diff /* * ao */;
    float sun_spec = specular(view_dir, directional_from, normal, shininess);
    float sun_diff = diffuse(directional_from, normal);
    vec4 light_spec = clamp(sun_spec * directional_color * shadow + point_spec, 0, 1);
    vec4 light_diff = clamp(sun_diff * directional_color * shadow + point_diff, 0, 1) /* * ao */; // consider 0.5 * ao + 0.5
    color += mat_diff * light_diff + light_spec; // specular highlights are white, so omit mat_spec

    color.a = mat_diff.a;
    // color = vec4(ao, ao, ao, 1.0);
    vec4 shadow_sample = texture(resolved_shadows, var_texcoord0);
    // shadow_sample = vec4(shadow * ao);
    color = vec4(shadow_sample.r, shadow_sample.r, shadow_sample.r, 1.0);
    // float fog_intensity = clamp((-var_frag_pos.z - FOG_NEAR) / (FOG_FAR - FOG_NEAR), 0, 1);
    float fog_intensity = smoothstep(FOG_NEAR, FOG_FAR, -var_frag_pos.z);
    color = mix(color, fog_color, fog_intensity);
    frag_color = clamp(color, 0.0, 1.0);
    // frag_color = texture(spec_light_sampler, var_texcoord0);
}
