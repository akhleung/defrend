#ifndef DEFREND_DEPTH_FUNCTIONS
#define DEFREND_DEPTH_FUNCTIONS

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

// vec2 rand(vec2 co) {
//     return vec2(
//         fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453),
//         fract(sin(dot(co.yx ,vec2(12.9898,78.233))) * 43758.5453)
//     ) * 0.00047;
// }

#endif
