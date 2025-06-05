#ifndef DEFREND_LIGHTING_FUNCTIONS
#define DEFREND_LIGHTING_FUNCTIONS

float linearizeDepth(float d, vec3 frustum_terms) {
    float zNdc  = 2.0 * d - 1.0;
    return frustum_terms.x / (frustum_terms.y - zNdc * frustum_terms.z);
}

vec3 viewPosFromLinearDepth(float z, vec2 uv, vec3 frustum_corner) {
    vec2  uvNdc = 2.0 * uv - 1.0;
    vec2  xyFar = frustum_corner.xy * uvNdc;
    float zNorm = z / frustum_corner.z;
    return vec3(xyFar * zNorm, z);
}

float hash12(vec2 v) {
    return fract(sin(dot(v, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 hash22(vec2 co) {
    return vec2(
        fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453),
        fract(sin(dot(co.yx ,vec2(12.9898,78.233))) * 43758.5453)
    );
}

float diffuse(vec3 to_light, vec3 normal_sample) {
    return max(dot(normal_sample, to_light), 0.0);
}

float specular(vec3 viewdir, vec3 lightdir, vec3 norm, float shiny) {
    vec3 H = normalize(viewdir + lightdir);
    return shiny == 0 ? 0 : pow(max(dot(norm, H), 0.0), shiny);
}

float attenuation(float d, float r_inner, float r_outer) {
    float falloff = 1.0 - smoothstep(r_inner, r_outer, d);
    return falloff * falloff;
}

// vec2 rand(vec2 co) {
//     return vec2(
//         fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453),
//         fract(sin(dot(co.yx ,vec2(12.9898,78.233))) * 43758.5453)
//     ) * 0.00047;
// }

#endif
