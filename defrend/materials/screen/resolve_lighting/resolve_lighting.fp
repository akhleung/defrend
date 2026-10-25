#version 420 core
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/lighting_functions.glsl"

in vec2 var_texcoord0;

uniform sampler2D albedo_sampler;
uniform sampler2D depth_buffer;
uniform sampler2D ssao_sampler;
uniform sampler2D light_sampler;

uniform lighting_fp {
	vec4 frustum_corner;
	vec4 frustum_terms;

	vec4 fog_params;
	vec4 fog_color;
	vec4 ambient_color;
};

layout(location = 0) out vec4 frag_color;

float FOG_NEAR		= fog_params.x;
float FOG_FAR		= fog_params.y;

void main() {
	vec4 albedo_sample		= texture(albedo_sampler, var_texcoord0);
	vec4 light_sample		= texture(light_sampler, var_texcoord0);
	vec4 light_diff			= vec4(light_sample.rgb, 1.0);
	vec4 light_spec			= vec4(light_sample.rgb * light_sample.a, 1.0);

	float depth			= texture(depth_buffer, var_texcoord0).r;
	float z				= linearizeDepth(depth, frustum_terms.xyz);
	vec3 var_frag_pos	= viewPosFromLinearDepth(z, var_texcoord0, frustum_corner.xyz);

	float ao = texture(ssao_sampler, var_texcoord0).r;
	float emissive = ceil(albedo_sample.a);
	vec4 mat_diff = vec4(albedo_sample.rgb, 1.0);

	vec4 color = ambient_color * mat_diff;
	color += mat_diff * clamp(light_diff + emissive, 0, 1);
	color *= ao; // consider (ao + 1) / 2
	color += light_spec; // we only support white specular highlights for now, so no mat_spec

	// vec4 color = ambient_color * mat_diff * ao;
	// we only support white specular highlights for now, so no mat_spec
	// color += mat_diff * clamp(light_diff + emissive, 0, 1) * ao + light_spec; // consider (ao + 1) / 2

	float fog_intensity = smoothstep(FOG_NEAR, FOG_FAR, -var_frag_pos.z);
	color = mix(color, fog_color, fog_intensity);
	color.a = mat_diff.a;
	frag_color = clamp(color, 0, 1);
}
