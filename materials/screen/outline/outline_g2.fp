#version 420 core
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/position_from_depth.glsl"

in vec2 var_texcoord0;

uniform sampler2D depth_buffer;
uniform sampler2D normal_sampler;
uniform sampler2D color_sampler;

uniform outline_g2_fp {
    vec4 params1;
    vec4 params2;
    vec4 frustum_corner;
    vec4 frustum_terms;
};

vec2	resolution			= vec2(params1.x, params1.y);
vec3	shadow_color		= vec3(0.0);
float	shadow_thickness	= 1.0;

out vec4 fragColor;

vec2 getDepth(vec2 uv) {
	float	raw_depth		= texture(depth_buffer, uv).r;
	float	depth			= linearizeDepth(raw_depth, frustum_terms.xyz);
	vec2	depth_data		= vec2(depth, raw_depth);
	return	depth_data;
}

void main() {

	float	depth_diff		= 0.0;
	vec2	depth_data		= getDepth(var_texcoord0);
	float	depth			= depth_data.x;
	vec3	color			= texture(color_sampler, var_texcoord0).rgb;
	vec3	c				= vec3(0);

	vec2	min_depth_data	= depth_data;
	float	min_depth		= 9999999.9;
	vec3	normal			= texture(normal_sampler, var_texcoord0).xyz * 2 - 1;

	for (float x = -shadow_thickness; x <= shadow_thickness;x += 1.0) {
		for (float y = -shadow_thickness; y <= shadow_thickness; y += 1.0) {
			
			if ((x == 0.0 && y == 0.0) || (shadow_thickness * shadow_thickness < (x*x + y*y))) continue;
			
			vec2 du_data = getDepth(var_texcoord0 + 1.0 * vec2(x, y) / resolution);
			vec2 dd_data = getDepth(var_texcoord0 + 0.5 * vec2(x, y) / resolution);
			
			float du = du_data.x;
			float dd = dd_data.x;
			
			float dd_diff = clamp(abs((depth - dd) - (dd - du)), 0.0, 1.0);

			float val = clamp(abs(depth - du), 0., 1.) / (x*x + y*y) * dd_diff*dd_diff * 5000.0;
			
			val = clamp(val, 0.0, 1.0);

			depth_diff += val;

			if (du < min_depth){
				min_depth = du;
				min_depth_data = du_data;
				c = texture(color_sampler, var_texcoord0 + vec2(x, y) / resolution).rgb;
				
				c *= clamp(0.5 + 0.5 * dot(normalize(vec2(x, y)), (vec2(0.0, 1.0))), 0.0, 1.0);
				
			}
			
			vec3 nu = texture(normal_sampler, var_texcoord0 + vec2(x, y) / resolution).rgb * 2.0 - 1.0;
			
			depth_diff += (1.0 - abs(dot(nu, normal))) / max(min(dd, depth), 2.0);
		}
	}

	depth_diff = smoothstep(0.2, 0.3, depth_diff);

	vec3 final = c * shadow_color;
	vec4 outline = vec4(final, 1.0);

	float alpha_mask = depth_diff;
	outline.a = clamp((alpha_mask) * 5., 0., 1.);

	fragColor.xyz = mix(color, outline.rgb, outline.a);
	fragColor.a = 1;
}
