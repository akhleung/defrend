#version 320 es
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/lighting_functions.glsl"

in mediump vec2 var_texcoord0;

uniform sampler2D depth_buffer;
uniform sampler2D normal_sampler;
uniform sampler2D color_sampler;

uniform outline_g_fp {
    mediump vec4 params1;
    mediump vec4 params2;
	mediump vec4 params3;
    mediump vec4 frustum_corner;
    mediump vec4 frustum_terms;
};

// outline
mediump float	depth_threshold;
mediump float	normal_threshold;
mediump float	normal_smoothing;

// thickness
mediump float	max_thickness;
mediump float	min_thickness;
mediump float	max_distance;
mediump float	min_distance;

// grazing prevention
mediump float	grazing_fresnel_power;
mediump float	grazing_angle_mask_power;
mediump float	grazing_angle_modulation_factor;

struct UVNeighbors {
	mediump vec2 center; 
	mediump vec2 left;     mediump vec2 right;     mediump vec2 up;          mediump vec2 down;
	mediump vec2 top_left; mediump vec2 top_right; mediump vec2 bottom_left; mediump vec2 bottom_right;
};

struct NeighborDepthSamples {
	mediump float c_d; 
	mediump float l_d;  mediump float r_d;  mediump float u_d;  mediump float d_d; 
	mediump float tl_d; mediump float tr_d; mediump float bl_d; mediump float br_d;
};

UVNeighbors getNeighbors(mediump vec2 center, mediump float width, mediump float aspect) {
	mediump vec2 h_offset = vec2(width * aspect * 0.001, 0.0);
	mediump vec2 v_offset = vec2(0.0, width * 0.001);
	UVNeighbors n;
	n.center = center;
	n.left   = center - h_offset;
	n.right  = center + h_offset;
	n.up     = center - v_offset;
	n.down   = center + v_offset;
	n.top_left     = center - (h_offset - v_offset);
	n.top_right    = center + (h_offset - v_offset);
	n.bottom_left  = center - (h_offset + v_offset);
	n.bottom_right = center + (h_offset + v_offset);
	return n;
}

mediump float getMinimumDepth(NeighborDepthSamples ds){
	return min(ds.c_d, min(ds.l_d, min(ds.r_d, min(ds.u_d, min(ds.d_d, min(ds.tl_d, min(ds.tr_d, min(ds.bl_d, ds.br_d))))))));
}

mediump float getLinearDepth(mediump vec2 uv) {
	return linearizeDepth(texture(depth_buffer, uv).r, frustum_terms.xyz);
}

NeighborDepthSamples getLinearDepthSamples(UVNeighbors uvs) {
	NeighborDepthSamples result;
	result.c_d  = getLinearDepth(uvs.center);
	result.l_d  = getLinearDepth(uvs.left);
	result.r_d  = getLinearDepth(uvs.right);
	result.u_d  = getLinearDepth(uvs.up);
	result.d_d  = getLinearDepth(uvs.down);
	result.tl_d = getLinearDepth(uvs.top_left);
	result.tr_d = getLinearDepth(uvs.top_right);
	result.bl_d = getLinearDepth(uvs.bottom_left);
	result.br_d = getLinearDepth(uvs.bottom_right);
	return result;
}

mediump float remap(mediump float v, mediump float from1, mediump float to1, mediump float from2, mediump float to2) {
	return (v - from1) / (to1 - from1) * (to2 - from2) + from2;
}

mediump float fresnel(mediump float amount, mediump vec3 normal, mediump vec3 view) {
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

mediump float getGrazingAngleModulation(mediump vec3 pixel_normal, mediump vec3 view) {
	mediump float x = clamp(((fresnel(grazing_fresnel_power, pixel_normal, view) - 1.0) / grazing_angle_mask_power) + 1.0, 0.0, 1.0);
	return (x + grazing_angle_modulation_factor) + 1.0;
}

mediump float detectEdgesDepth(NeighborDepthSamples depth_samples, mediump vec3 pixel_normal, mediump vec3 view) {
	mediump float n_total = 
		depth_samples.l_d + 
		depth_samples.r_d + 
		depth_samples.u_d + 
		depth_samples.d_d + 
		depth_samples.tl_d + 
		depth_samples.tr_d + 
		depth_samples.bl_d + 
		depth_samples.br_d;
	
	mediump float t = depth_threshold * getGrazingAngleModulation(pixel_normal, view);
	return step(t, n_total - (depth_samples.c_d * 8.0));
}

mediump float detectEdgesNormal(UVNeighbors uvs, sampler2D normTex){
	mediump vec3 n_u = texture(normTex, uvs.up).xyz;
	mediump vec3 n_d = texture(normTex, uvs.down).xyz;
	mediump vec3 n_l = texture(normTex, uvs.left).xyz;
	mediump vec3 n_r = texture(normTex, uvs.right).xyz;
	mediump vec3 n_tl = texture(normTex, uvs.top_left).xyz;
	mediump vec3 n_tr = texture(normTex, uvs.top_right).xyz;
	mediump vec3 n_bl = texture(normTex, uvs.bottom_left).xyz;
	mediump vec3 n_br = texture(normTex, uvs.bottom_right).xyz;
	
	mediump vec3 normalFiniteDifference0 = n_tr - n_bl;
	mediump vec3 normalFiniteDifference1 = n_tl - n_br;
	mediump vec3 normalFiniteDifference2 = n_l - n_r;
	mediump vec3 normalFiniteDifference3 = n_u - n_d;
	
	mediump float edgeNormal = sqrt(
		dot(normalFiniteDifference0, normalFiniteDifference0) + 
		dot(normalFiniteDifference1, normalFiniteDifference1) + 
		dot(normalFiniteDifference2, normalFiniteDifference2) + 
		dot(normalFiniteDifference3, normalFiniteDifference3)
	);
	
	return smoothstep(normal_threshold - normal_smoothing, normal_threshold + normal_smoothing, edgeNormal);
}

out mediump vec4 fragColor;

void main() {

	mediump vec2	resolution = vec2(params1.x, params1.y);
	depth_threshold		= params1.z;
	normal_threshold	= params1.w;
	normal_smoothing	= params2.x;
	max_thickness	= params2.y;
	min_thickness	= params2.z;
	max_distance	= params2.w;
	min_distance	= params3.x;
	grazing_fresnel_power			= params3.y;
	grazing_angle_mask_power		= params3.z;
	grazing_angle_modulation_factor	= params3.w;


	mediump float aspect = float(resolution.y) / float(resolution.x);
	UVNeighbors n = getNeighbors(var_texcoord0, max_thickness, aspect);
	NeighborDepthSamples depth_samples = getLinearDepthSamples(n);

	mediump float min_d = getMinimumDepth(depth_samples);
	mediump float thickness = clamp(remap(min_d, min_distance, max_distance, max_thickness, min_thickness), min_thickness, max_thickness);
	mediump float fade_a = clamp(remap(min_d, min_distance, max_distance, 1.0, 0.0), 0.0, 1.0);

	n = getNeighbors(var_texcoord0, thickness, aspect);
	depth_samples = getLinearDepthSamples(n);

	mediump vec3 pixel_normal = texture(normal_sampler, var_texcoord0).xyz;

	mediump float ld = getLinearDepth(var_texcoord0);
	mediump vec3 vpos = viewPosFromLinearDepth(ld, var_texcoord0, frustum_corner.xyz);
	
	mediump float depthEdges = detectEdgesDepth(depth_samples, pixel_normal, -vpos);
	
	mediump float normEdges = min(detectEdgesNormal(n, normal_sampler), 1.0);
	
	mediump vec4 color = texture(color_sampler, var_texcoord0);
	mediump vec4 outlineColor = color * 0.25;
	outlineColor.a = max(depthEdges, normEdges) * outlineColor.a * fade_a;
	fragColor.rgb = mix(color.rgb, outlineColor.xyz, outlineColor.a);
	fragColor.a = 1.0;
}
