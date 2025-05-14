#version 420
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/position_from_depth.glsl"

in vec2 var_texcoord0;

uniform sampler2D depth_buffer;
uniform sampler2D color_sampler;
uniform sampler2D normal_sampler;

uniform outline_fp {
	vec4 params1;
	vec4 params2;
	vec4 frustum_corner;
	vec4 frustum_terms;
};

vec2	resolution		= vec2(params1.x, params1.y);
float	min_separation	= params1.z;
float	max_separation	= params1.w;
float	min_threshold	= params2.x;
float	max_threshold	= params2.y;
int		radius			= int(params2.z);
vec3 	color_modifier	= vec3(0.324, 0.063, 0.099);

out vec4 fragColor;

void main() {
	float	depth	= texture(depth_buffer, var_texcoord0).r;
    float	z		= linearizeDepth(depth, frustum_terms.xyz);
	vec3	origin	= viewPosFromLinearDepth(z, var_texcoord0, frustum_corner.xyz);
	vec3	normal	= texture(normal_sampler, var_texcoord0).xyz * 2 - 1;
    float	z_norm	= (z - frustum_corner.w) / (frustum_corner.z - frustum_corner.w);
	float	angle	= abs(dot(-origin, normal));

	float	separation	= mix(min_separation, max_separation, 1 - z_norm);
	float	max_d		= 0.0;
	for (int i = -radius; i <= radius; ++i) {
		for (int j = -radius; j <= radius; ++j) {
			vec2	s_uv	= var_texcoord0 + vec2(i, j) / resolution;
			float	s_depth	= texture(depth_buffer, s_uv).r;
			float	s_z		= linearizeDepth(s_depth, frustum_terms.xyz);
			max_d = max(max_d, abs(z - s_z));
		}
	}
	float diff = 1 - smoothstep(min_threshold, max_threshold, max_d) * angle;
	vec3 line_color = texture(color_sampler, var_texcoord0).rgb;
	fragColor = vec4(line_color.rgb * diff + fragColor.rgb * (1 - diff), 1.0);
	fragColor = vec4(line_color, 1.0);
	fragColor = vec4(diff, diff, diff, 1.0);
}
