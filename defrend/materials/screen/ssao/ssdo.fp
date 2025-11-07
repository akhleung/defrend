#version 420 core
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/lighting_functions.glsl"

in vec2 var_texcoord0;

uniform sampler2D depth_buffer;
uniform sampler2D normal_sampler;

uniform ssao_fp {
	vec4 params1;
	vec4 params2;
	vec4 frustum_corner;
	vec4 frustum_terms;
};

int   samples		= int(params1.x);
float intensity		= params1.y;
float bias_angle	= params1.z;
float bias_dist		= params1.w;
float min_distance	= params2.x;
float max_distance	= params2.y;
float attn			= params2.z;
float radius		= params2.w;

const float goldenAngle = 2.4;

const float fudge_factor_l0 = 2.0;
const float fudge_factor_l1 = 10.0;

const float sh2_weight_l0 = fudge_factor_l0 * 0.28209; //0.5*sqrt(1.0/pi);
const vec3 sh2_weight_l1 = vec3(fudge_factor_l1 * 0.48860); //0.5*sqrt(3.0/pi);

vec4 sh2_weight = vec4(sh2_weight_l1, sh2_weight_l0) / samples;

out vec4 frag_color;

void main() {

	float depth		= texture(depth_buffer, var_texcoord0).r;
	float z			= linearizeDepth(depth, frustum_terms.xyz);
	vec3  origin	= viewPosFromLinearDepth(z, var_texcoord0, frustum_corner.xyz);
	float z_norm	= (origin.z - frustum_corner.w) / (frustum_corner.z - frustum_corner.w);
  	vec3  normal	= texture(normal_sampler, var_texcoord0).xyz * 2.0 - 1.0;
	float rotation	= hash12(var_texcoord0 * 100) * 6.28;
	float r			= radius / abs(origin.z);
	float rStart	= r * z_norm * bias_dist;
	float rStep		= (r - rStart) / samples;
	float ssao		= 0.0;
	vec4  ssdo		= vec4(0.0);

	for (int i = 0; i < samples; ++i, rotation += goldenAngle) {
		vec2  offsetUV		= var_texcoord0 + vec2(sin(rotation), cos(rotation)) * (rStart + rStep * (i + 1));
		float offsetDepth	= texture(depth_buffer, offsetUV).r;
		float offsetZ		= linearizeDepth(offsetDepth, frustum_terms.xyz);
		vec3  offset		= viewPosFromLinearDepth(offsetZ, offsetUV, frustum_corner.xyz);

		vec3  diff      = offset - origin;
		vec3  ndiff		= normalize(diff);
		float fadeout	= 1.0 - clamp(length(diff) / max_distance, 0, 1);
		float angle		= dot(normal, ndiff);

		ssdo += step(bias_angle, angle) * fadeout * fadeout * sh2_weight * vec4(ndiff, 1);
	}

	frag_color = depth == 1 ? vec4(1) : ssdo;
}
