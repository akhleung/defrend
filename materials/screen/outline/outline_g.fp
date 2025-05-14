#version 420 core
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/position_from_depth.glsl"

in vec2 var_texcoord0;

uniform sampler2D depth_buffer;
uniform sampler2D normal_sampler;
uniform sampler2D color_sampler;

uniform outline_g_fp {
    vec4 params1;
    vec4 params2;
    vec4 frustum_corner;
    vec4 frustum_terms;
};

vec2	resolution		= vec2(params1.x, params1.y);

float depth_threshold = 0.025;
float normal_threshold = 0.5;
float normal_smoothing = 0.25;

// float max_thickness = 1.3;
float max_thickness = 0.6;
float min_thickness = 0.5;
float max_distance = 75.0;
float min_distance = 2.0;

float grazing_fresnel_power = 5.0;
float grazing_angle_mask_power = 1.0;
float grazing_angle_modulation_factor = 50.0;

struct UVNeighbors {
	vec2 center; 
	vec2 left;     vec2 right;     vec2 up;          vec2 down;
	vec2 top_left; vec2 top_right; vec2 bottom_left; vec2 bottom_right;
};

struct NeighborDepthSamples {
	float c_d; 
	float l_d;  float r_d;  float u_d;  float d_d; 
	float tl_d; float tr_d; float bl_d; float br_d;
};

UVNeighbors getNeighbors(vec2 center, float width, float aspect) {
	vec2 h_offset = vec2(width * aspect * 0.001, 0.0);
	vec2 v_offset = vec2(0.0, width * 0.001);
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

float getMinimumDepth(NeighborDepthSamples ds){
	return min(ds.c_d, min(ds.l_d, min(ds.r_d, min(ds.u_d, min(ds.d_d, min(ds.tl_d, min(ds.tr_d, min(ds.bl_d, ds.br_d))))))));
}

float getLinearDepth(vec2 uv) {
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

float remap(float v, float from1, float to1, float from2, float to2) {
	return (v - from1) / (to1 - from1) * (to2 - from2) + from2;
}

float fresnel(float amount, vec3 normal, vec3 view) {
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

float getGrazingAngleModulation(vec3 pixel_normal, vec3 view) {
	float x = clamp(((fresnel(grazing_fresnel_power, pixel_normal, view) - 1.0) / grazing_angle_mask_power) + 1.0, 0.0, 1.0);
	return (x + grazing_angle_modulation_factor) + 1.0;
}

float detectEdgesDepth(NeighborDepthSamples depth_samples, vec3 pixel_normal, vec3 view) {
	float n_total = 
		depth_samples.l_d + 
		depth_samples.r_d + 
		depth_samples.u_d + 
		depth_samples.d_d + 
		depth_samples.tl_d + 
		depth_samples.tr_d + 
		depth_samples.bl_d + 
		depth_samples.br_d;
	
	float t = depth_threshold * getGrazingAngleModulation(pixel_normal, view);
	return step(t, n_total - (depth_samples.c_d * 8.0));
}

float detectEdgesNormal(UVNeighbors uvs, sampler2D normTex){
	vec3 n_u = texture(normTex, uvs.up).xyz;
	vec3 n_d = texture(normTex, uvs.down).xyz;
	vec3 n_l = texture(normTex, uvs.left).xyz;
	vec3 n_r = texture(normTex, uvs.right).xyz;
	vec3 n_tl = texture(normTex, uvs.top_left).xyz;
	vec3 n_tr = texture(normTex, uvs.top_right).xyz;
	vec3 n_bl = texture(normTex, uvs.bottom_left).xyz;
	vec3 n_br = texture(normTex, uvs.bottom_right).xyz;
	
	vec3 normalFiniteDifference0 = n_tr - n_bl;
	vec3 normalFiniteDifference1 = n_tl - n_br;
	vec3 normalFiniteDifference2 = n_l - n_r;
	vec3 normalFiniteDifference3 = n_u - n_d;
	
	float edgeNormal = sqrt(
		dot(normalFiniteDifference0, normalFiniteDifference0) + 
		dot(normalFiniteDifference1, normalFiniteDifference1) + 
		dot(normalFiniteDifference2, normalFiniteDifference2) + 
		dot(normalFiniteDifference3, normalFiniteDifference3)
	);
	
	return smoothstep(normal_threshold - normal_smoothing, normal_threshold + normal_smoothing, edgeNormal);
}

out vec4 fragColor;

void main() {

	float aspect = float(resolution.y) / float(resolution.x);
	UVNeighbors n = getNeighbors(var_texcoord0, max_thickness, aspect);
	NeighborDepthSamples depth_samples = getLinearDepthSamples(n);

	float min_d = getMinimumDepth(depth_samples);
	float thickness = clamp(remap(min_d, min_distance, max_distance, max_thickness, min_thickness), min_thickness, max_thickness);
	float fade_a = clamp(remap(min_d, min_distance, max_distance, 1.0, 0.0), 0.0, 1.0);

	n = getNeighbors(var_texcoord0, thickness, aspect);
	depth_samples = getLinearDepthSamples(n);

	vec3 pixel_normal = texture(normal_sampler, var_texcoord0).xyz;

	float ld = getLinearDepth(var_texcoord0);
	vec3 vpos = viewPosFromLinearDepth(ld, var_texcoord0, frustum_corner.xyz);
	
	float depthEdges = detectEdgesDepth(depth_samples, pixel_normal, -vpos);
	
	float normEdges = min(detectEdgesNormal(n, normal_sampler), 1.0);
	
	vec4 color = texture(color_sampler, var_texcoord0);
	vec4 outlineColor = color * 0.25;
	outlineColor.a = max(depthEdges, normEdges) * outlineColor.a * fade_a;
	fragColor.rgb = mix(color.rgb, outlineColor.xyz, outlineColor.a);
	fragColor.a = 1;
}
