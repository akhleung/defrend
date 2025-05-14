#version 420 core
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/position_from_depth.glsl"

in vec2 var_texcoord0;

uniform sampler2D depth_buffer;
uniform sampler2D normal_sampler;

uniform ssao_fp {
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

out vec4 frag_color;

float getLinearDepth(vec2 uv) {
	return linearizeDepth(texture(depth_buffer, uv).r, frustum_terms.xyz);
}

void main() {

    float	depth_threshold = 0.01;

	float	depthOG = texture(depth_buffer, var_texcoord0).r;
	float	z       = linearizeDepth(depthOG, frustum_terms.xyz);
    float	z_norm  = (z - frustum_corner.w) / (frustum_corner.z - frustum_corner.w);
    vec3	normal	= texture(normal_sampler, var_texcoord0).xyz;
	vec3	origin	= viewPosFromLinearDepth(z, var_texcoord0, frustum_corner.xyz);

    float	depthSW = getLinearDepth(var_texcoord0 + vec2(-1, -1) / resolution);
    float	depthNE = getLinearDepth(var_texcoord0 + vec2(1, 1) / resolution);
    float	depthSE = getLinearDepth(var_texcoord0 + vec2(1, -1) / resolution);
    float	depthNW = getLinearDepth(var_texcoord0 + vec2(-1, 1) / resolution);

	float	min_d	= min(depthSW, min(depthNE, min(depthSE, min(depthNW, depthOG))));

    float	diffSwNe	= depthSW - depthNE;
    float	diffSeNw	= depthSE - depthNW;

    float	edgeDiff	= sqrt(pow(diffSwNe, 2) + pow(diffSeNw, 2)) * 100;

    depth_threshold *= depthOG;
    edgeDiff = edgeDiff > depth_threshold ? 1 : 0;
    // edgeDiff = smoothstep(depth_threshold / 2, depth_threshold, edgeDiff);

    // edgeDiff = 1 - edgeDiff;
    frag_color = vec4(edgeDiff, edgeDiff, edgeDiff, 1.0);
}
