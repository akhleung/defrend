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

float m_NormalThreshold = 0.5;
float m_DepthThreshold = 0.2;
float m_NormalSensitivity = 1;
float m_DepthSensitivity = 1;
float m_EdgeWidth = 1;

out vec4 fragColor;

vec4 getNormalDepth(vec2 uv) {
	float	depth	= texture(depth_buffer, uv).r;
	vec4	normal	= texture(normal_sampler, uv);
	float z = linearizeDepth(depth, frustum_terms.xyz);
	return vec4(normal.rgb, depth);
}

void main() {
	float	normal_threshold = 0.4;
    float	depth_threshold = 0.01;
	float	depth_normal_threshold = 0.1;
	float	depth_normal_threshold_scale = 50;

	vec3	normal = texture(normal_sampler, var_texcoord0).xyz * 2.0 - 1.0;
	float	depth = texture(depth_buffer, var_texcoord0).r;
	float	z = linearizeDepth(depth, frustum_terms.xyz);
	vec3	origin = viewPosFromLinearDepth(z, var_texcoord0, frustum_corner.xyz);
	float	angle = 1.0 - dot(normal, -origin);
    float	z_norm	= (z - frustum_corner.w) / (frustum_corner.z - frustum_corner.w);

	vec4	n1	= getNormalDepth(var_texcoord0 + vec2(-1, -1) / resolution);
	vec4	n2	= getNormalDepth(var_texcoord0 + vec2(1, 1) / resolution);
	vec4	n3	= getNormalDepth(var_texcoord0 + vec2(-1, 1) / resolution);
	vec4	n4	= getNormalDepth(var_texcoord0 + vec2(1, -1) / resolution);

	vec4 d1 = n1 - n2;
	vec4 d2 = n3 - n4;

	float depthDelta = sqrt(d1.w * d1.w + d2.w * d2.w) * 250;
	float normalDelta = sqrt(dot(d1.xyz, d1.xyz) + dot(d2.xyz, d2.xyz));
	// vec4 diagonalDelta = abs(n1 - n2) + abs(n3 - n4);
	// vec4 diagonalDelta = sqrt(d1 + d2);

    // float normalDelta = dot(diagonalDelta.xyz, vec3(1.0));
    // float depthDelta = diagonalDelta.w * 100;

	float normalThreshold01 = clamp(0, 1, (angle - depth_normal_threshold) / (1 - depth_normal_threshold));
	float nt1 = smoothstep(depth_normal_threshold, 1, angle);
	float nt = nt1 * depth_normal_threshold_scale + 1;

	depth_threshold *= depth * nt;
	// float edgeDepth = depthDelta > depth_threshold ? 1 : 0;
	float edgeDepth = smoothstep(depth_threshold / 2, depth_threshold, depthDelta);
	// float edgeNormal = normalDelta > normal_threshold ? 1 : 0;
	float edgeNormal = smoothstep(normal_threshold / 2, normal_threshold, normalDelta);
	float edge = max(edgeDepth, edgeNormal);
	vec3 color = texture(color_sampler, var_texcoord0).rgb;
	fragColor = vec4(mix(vec3(1), color * 0.5, edge), 1);
	fragColor = vec4(edge, edge, edge, 1);


    // normalDelta = clamp((normalDelta - m_NormalThreshold) * m_NormalSensitivity, 0.0, 1.0);
    // depthDelta  = clamp((depthDelta - m_DepthThreshold * depth) * m_DepthSensitivity,    0.0, 1.0);

	// float edgeAmount = clamp(normalDelta + depthDelta, 0.0, 1.0);
	// vec3 color = texture(color_sampler, var_texcoord0).rgb;
	// fragColor = vec4(mix(vec3(1), color * 0.85, edgeAmount), 1);
}
