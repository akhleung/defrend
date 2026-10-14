#version 420 core
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/lighting_functions.glsl"

#define PI 3.141592654
#define X vec3(1, 0, 0)
#define Y vec3(0, 1, 0)

in vec3 var_center;
in vec3 var_center_w;
in vec3 var_color;
in float var_radius;
in float var_attn;
#ifdef EDITOR
in vec3 var_normal;
#endif

uniform sampler2D depth_buffer;
uniform sampler2D normal_sampler;
uniform samplerCube shadow_map;

uniform point_light_fp {
    vec4 frustum_corner;
    vec4 frustum_terms;
	mat4 mtx_view_inv;
	vec4 shadow_params1; // x: near bias, y: far bias, z: soft penumbras, w: pcf samples
	vec4 shadow_params2; // x: poisson samples, y: poisson scale, z: hash factor, w: hash scale
	vec4 texel_size; // x: texel size, y: light radius
};

float	near_bias		= shadow_params1.x;
float	far_bias		= shadow_params1.y;
bool	SOFT_PENUMBRAS	= bool(shadow_params1.z);
int		PCF_SAMPLES		= int(shadow_params1.w);
int		POISSON_SAMPLES	= int(shadow_params2.x);
float	POISSON_SCALE	= shadow_params2.y;
float	HASH_FACTOR		= shadow_params2.z;
float	HASH_SCALE		= shadow_params2.w;

vec3 pcf_kernel[] = vec3[](
	vec3(-1, -1, -1),
	vec3(0, -1, -1),
	vec3(1, -1, -1),

	vec3(-1, 0, -1),
	// vec3(0, 0, -1),
	vec3(1, 0, -1),

	vec3(-1, 1, -1),
	vec3(0, 1, -1),
	vec3(1, 1, -1),

	vec3(-1, -1, 0),
	// vec3(0, -1, 0),
	vec3(1, -1, 0),

	// vec3(-1, 0, 0),
	// vec3(0, 0, 0),
	// vec3(1, 0, 0),

	vec3(-1, 1, 0),
	// vec3(0, 1, 0),
	vec3(1, 1, 0),

	vec3(-1, -1, 1),
	vec3(0, -1, 1),
	vec3(1, -1, 1),

	vec3(-1, 0, 1),
	// vec3(0, 0, 1),
	vec3(1, 0, 1),

	vec3(-1, 1, 1),
	vec3(0, 1, 1),
	vec3(1, 1, 1)
);

layout(location = 0) out vec4 light_out;

void main() {
	ivec2 frag_coord = ivec2(gl_FragCoord.xy);
	float depth = texelFetch(depth_buffer, frag_coord, 0).r;
	float z = linearizeDepth(depth, frustum_terms.xyz);
	vec2 screen_uv = gl_FragCoord.xy / textureSize(depth_buffer, 0);
	vec3 geom_pos = viewPosFromLinearDepth(z, screen_uv, frustum_corner.xyz);
	vec4 normal_sample = texelFetch(normal_sampler, frag_coord, 0);
	float shininess = normal_sample.a * 255;
	vec3 to_light = var_center - geom_pos;
	float d = length(to_light);
	if (d > var_radius) discard;

	vec3 normal = normalize(normal_sample.xyz * 2.0 - 1.0);
	float bias = mix(near_bias, far_bias, d / var_radius);
	vec4 geom_pos_w = mtx_view_inv * vec4(geom_pos + normal * bias, 1.0);
	vec3 geom_pos_l = geom_pos_w.xyz - var_center_w;

	d = length(geom_pos_l);
	float occludee_d = d / var_radius;
	float light = 0;
	for (int i = 0; i < 20; ++i) {
		vec3 offset = pcf_kernel[i] * 0.04;
		light += texture(shadow_map, geom_pos_l + offset).r < occludee_d ? 0 : 1;
	}
	light /= 20;

	// do the actual lighting calculations
	vec3 to_view = -geom_pos;
	vec3 to_light_normalized = normalize(to_light);
	float diff = diffuse(to_light_normalized, normal);
	float spec = specular(normalize(to_view), to_light_normalized, normal, shininess);
	float attn = attn_inv_pow(d, var_radius, var_attn);
	light_out = vec4(var_color * diff * attn, spec * attn) * light;

	#ifdef EDITOR // visualization for viewing point light volumes in the editor
	vec3 lat_normal = normalize(vec3(var_normal.x, 0, var_normal.z));
	vec2 dots = abs(vec2(dot(lat_normal, X), dot(var_normal, Y)));
	vec2 rads = acos(dots);
	vec2 degs = floor(rads * 180 / PI);
	vec2 rems = fract(degs / 24);
	if (rems.x == 0 || rems.y == 0) {
		light_out = vec4(var_color, 1.0);
	} else if (int(gl_FragCoord.y) % 4 == 0 && int(gl_FragCoord.x) % 2 == 0) {
		light_out = vec4(var_color, 1.0);
	} else if (int(gl_FragCoord.y) % 4 == 0) {
		discard;
	} else if (int(gl_FragCoord.y) % 2 == 0 && int(gl_FragCoord.x) % 2 != 0) {
		light_out = vec4(var_color, 1.0);
	} else {
		discard;
	}
	light_out = vec4(var_color, 1.0);
	#endif
}
