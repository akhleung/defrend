#ifndef DEFREND_LIGHTING_FUNCTIONS
#define DEFREND_LIGHTING_FUNCTIONS

mediump float linearizeDepth(mediump float d, mediump vec3 frustum_terms) {
    mediump float zNdc  = 2.0 * d - 1.0;
    return frustum_terms.x / (frustum_terms.y - zNdc * frustum_terms.z);
}

mediump vec3 viewPosFromLinearDepth(mediump float z, mediump vec2 uv, mediump vec3 frustum_corner) {
    mediump vec2  uvNdc = 2.0 * uv - 1.0;
    mediump vec2  xyFar = frustum_corner.xy * uvNdc;
    mediump float zNorm = z / frustum_corner.z;
    return vec3(xyFar * zNorm, z);
}

#define MOD3 vec3(.1031,.11369,.13787)

// float hash12(vec2 v) {
//     return fract(sin(dot(v, vec2(12.9898, 78.233))) * 43758.5453);
// }

// vec2 hash22(vec2 co) {
//     return vec2(
//         fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453),
//         fract(sin(dot(co.yx ,vec2(12.9898,78.233))) * 43758.5453)
//     );
// }

mediump float hash12(mediump vec2 p) {
	mediump vec3 p3  = fract(vec3(p.xyx) * MOD3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

mediump vec2 hash22(mediump vec2 p) {
	mediump vec3 p3 = fract(vec3(p.xyx) * MOD3);
    p3 += dot(p3, p3.yzx+19.19);
    return fract(vec2((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y));
}

mediump vec2 hash23(mediump vec3 p3) {
	p3 = fract(p3 * MOD3);
    p3 += dot(p3, p3.yzx + 19.19);
    // return fract((p3.xx + p3.yz) * p3.zy);
    return fract(vec2((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y));
}

mediump vec3 normal_from_rg(mediump vec2 rg) {
    rg = 2.0 * rg - 1.0;
    return normalize(vec3(rg.x, rg.y, sqrt(1.0 - rg.x * rg.x - rg.y * rg.y)));
}

mediump vec2 normal_to_rg(mediump vec3 normal) {
    return (0.5 * normalize(normal) + 0.5).rg;
}

float rgba_to_float(vec4 rgba) {
    return dot(rgba, vec4(1.0, 1.0/255.0, 1.0/65025.0, 1.0/16581375.0));
}

vec4 float_to_rgba(float v) {
    vec4 enc = vec4(1.0, 255.0, 65025.0, 16581375.0) * v;
    enc = fract(enc);
    enc -= enc.yzww * vec4(1.0/255.0, 1.0/255.0, 1.0/255.0, 0.0);
    return enc;
}

mediump float diffuse(mediump vec3 to_light, mediump vec3 normal_sample) {
    return max(dot(normal_sample, to_light), 0.0);
}

mediump float specular(mediump vec3 viewdir, mediump vec3 lightdir, mediump vec3 norm, mediump float shiny) {
    mediump vec3 H = normalize(viewdir + lightdir);
    return shiny == 0.0 ? 0.0 : pow(max(dot(norm, H), 0.0), shiny);
}

mediump float attenuation(mediump float d, mediump float r_inner, mediump float r_outer) {
    mediump float falloff = 1.0 - smoothstep(r_inner, r_outer, d);
    return falloff * falloff;
}

// vec2 rand(vec2 co) {
//     return vec2(
//         fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453),
//         fract(sin(dot(co.yx ,vec2(12.9898,78.233))) * 43758.5453)
//     ) * 0.00047;
// }

#endif
