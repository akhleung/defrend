#version 420 core
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/lighting_functions.glsl"

in mat4 mtx_worldview_inv;
in vec3 var_frag_pos;
in vec3 var_T;
in vec2 var_texcoord0;
#ifdef EDITOR
in vec3 var_vertex;
#endif

// samplers from the decal
uniform sampler2D albedo_map;
uniform sampler2D normal_map;
uniform sampler2D spec_glow_map;

// samplers from the g-buffer
uniform sampler2D g_normal_map;
uniform sampler2D depth_buffer;

uniform decal_fp {
    vec4 frustum_corner;
    vec4 frustum_terms;
};

layout(location = 0) out vec4 albedo_out;
layout(location = 1) out vec4 normal_out;
layout(location = 2) out vec4 orm_out;
layout(location = 3) out vec4 emissive_out;

vec3 perturb_normal(vec2 texcoord) {
    // construct a tangent frame based on the decal tangent, orthogonalized to the scene normal
    vec3 N = texelFetch(g_normal_map, ivec2(gl_FragCoord.xy), 0).xyz * 2.0 - 1.0;
    vec3 T = normalize(var_T - dot(var_T, N) * N);
    vec3 B = cross(N, T);
    mat3 TBN = mat3(T, B, N);
    return normalize(TBN * (texture(normal_map, texcoord).xyz * 2.0 - 1.0));
}

void main() {
    // reconstruct the position of the scene fragment that's overlapped by this decal projector fragment
	vec2 texcoord = gl_FragCoord.xy / textureSize(depth_buffer, 0);
	float depth = texture(depth_buffer, texcoord).r;
    float z = linearizeDepth(depth, frustum_terms.xyz);
    vec4 g_position = vec4(viewPosFromLinearDepth(z, texcoord, frustum_corner.xyz), 1.0);

    // put the scene fragment into model space (i.e., relative to the decal projector box)
    vec4 d_position = mtx_worldview_inv * g_position;
    vec3 abs_pos = abs(d_position.xyz);
    // discard this fragment if it's outside the projector box ([-0.5, 0.5])
    if (abs_pos.x > 0.5 || abs_pos.y  > 0.5 || abs_pos.z > 0.5) discard;

    // the scene fragment is inside the projector, so use its model-space position to sample the decal texture
    d_position += 0.5; // bias [-0.5, 0.5] -> [0, 1]
    vec4 decal_color = texture(albedo_map, d_position.xy);
    vec4 decal_spec_glow = texture(spec_glow_map, d_position.xy);
    #ifndef EDITOR
    if (decal_color.a == 0) discard; // avoid writing normals, etc
    #endif
    albedo_out      = decal_color;
    // calculate the decal fragment's normal relative to the underlying scene fragment's normal
    normal_out      = vec4(perturb_normal(d_position.xy) * 0.5 + 0.5, decal_spec_glow.r);
	orm_out			= vec4(0);
	emissive_out	= vec4(decal_color.rgb * decal_spec_glow.g, 1.0);

	#ifdef EDITOR // visualization for viewing decal projector boxes in the editor
    vec3 mags = abs(var_vertex);
    float edge = 0.4825;
    vec3 rems = fract(floor(mags * 100) / 10);
    float line_thickness = 0.1;
    if (var_vertex.z == 0.5) {
        albedo_out = texture(albedo_map, var_texcoord0);
    } else if (mags.x > edge && mags.y > edge || mags.y > edge && mags.z > edge || mags.x > edge && mags.z > edge) {
		albedo_out = vec4(1);
	} else if (rems.x < line_thickness && rems.y < line_thickness) {
        albedo_out = vec4(1);
	} else if (int(gl_FragCoord.y) % 4 == 0 && int(gl_FragCoord.x) % 2 == 0) {
		albedo_out = vec4(1);
	} else if (int(gl_FragCoord.y) % 4 == 0) {
		discard;
	} else if (int(gl_FragCoord.y) % 2 == 0 && int(gl_FragCoord.x) % 2 != 0) {
		albedo_out = vec4(1);
    } else {
		discard;
	}
	#endif
}
