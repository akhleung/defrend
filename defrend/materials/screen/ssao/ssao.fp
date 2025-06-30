#version 320 es
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/lighting_functions.glsl"

in mediump vec2 var_texcoord0;

uniform sampler2D depth_buffer;
uniform sampler2D normal_sampler;

uniform ssao_fp {
	mediump vec4 params1;
	mediump vec4 params2;
	mediump vec4 frustum_corner;
	mediump vec4 frustum_terms;
};


const mediump float goldenAngle = 2.4;

out mediump vec4 frag_color;

void main() {

			int		samples			= int(params1.x);
	mediump float	intensity		= params1.y;
	mediump float	bias_angle		= params1.z;
	mediump float	bias_dist		= params1.w;
	mediump float	min_distance	= params2.x;
	mediump float	max_distance	= params2.y;
	mediump float	attn			= params2.z;
	mediump float	radius			= params2.w;

	mediump float depth		= texture(depth_buffer, var_texcoord0).r;
	if (depth == 1.0) {
		frag_color = vec4(1);
		return;
	}
	mediump float z			= linearizeDepth(depth, frustum_terms.xyz);
	mediump vec3  origin	= viewPosFromLinearDepth(z, var_texcoord0, frustum_corner.xyz);
	mediump float z_norm	= (origin.z - frustum_corner.w) / (frustum_corner.z - frustum_corner.w);
  	mediump vec3  normal	= texture(normal_sampler, var_texcoord0).xyz * 2.0 - 1.0;
	mediump float rotation	= hash12(var_texcoord0 * 100.0) * 6.28;
	mediump float r			= radius / abs(origin.z);
	mediump float rStart	= r * z_norm * bias_dist;
	mediump float rStep		= (r - rStart) / float(samples);
	mediump float ao		= 0.0;

	for (int i = 0; i < samples; ++i, rotation += goldenAngle) {
		mediump vec2  offsetUV		= var_texcoord0 + vec2(sin(rotation), cos(rotation)) * (rStart + rStep * float(i + 1));
		mediump float offsetDepth	= texture(depth_buffer, offsetUV).r;
		mediump float offsetZ		= linearizeDepth(offsetDepth, frustum_terms.xyz);
		mediump vec3  offset		= viewPosFromLinearDepth(offsetZ, offsetUV, frustum_corner.xyz);

		mediump vec3  diff      = offset - origin;
		mediump float fadeout   = 1.0 - smoothstep(min_distance, max_distance, length(diff) * attn);
		mediump float incidence = smoothstep(bias_angle, 1.0, dot(normal, normalize(diff)));
		ao += incidence * fadeout;
	}

	frag_color = vec4(1.0 - ao / float(samples) * intensity);
}
