#version 420 core

in vec2 var_texcoord0;

uniform sampler2D depth_buffer;
uniform sampler2D normal_sampler;

uniform ssao_fp {
    vec4 params1;
    vec4 params2;
    vec4 frustum_corner;
    vec4 frustum_terms;
};

int   samples      = int(params1.x);
float intensity    = params1.y;
float bias_angle   = params1.z;
float bias_dist    = params1.w;
float min_distance = params2.x;
float max_distance = params2.y;
float attenuation  = params2.z;
float radius       = params2.w;

const float goldenAngle = 2.4;

out vec4 frag_color;

float linearizeDepth(float d) {
    float zNdc  = 2.0 * d - 1.0;
    return frustum_terms.x / (frustum_terms.y - zNdc * frustum_terms.z);
}

vec3 viewPosFromLinearDepth(float z, vec2 uv) {
    vec2  uvNdc = 2.0 * uv - 1.0;
    vec2  xyFar = frustum_corner.xy * uvNdc;
    float zNorm = z / frustum_corner.z;
    return vec3(xyFar * zNorm, z);
}

float hash(vec2 v) {
    return fract(sin(dot(v, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {

    float depth    = texture(depth_buffer, var_texcoord0).r;
    if (depth == 1.0) {
        frag_color = vec4(1);
        return;
    }
    float z        = linearizeDepth(depth);
    vec3  origin   = viewPosFromLinearDepth(z, var_texcoord0);
    float z_norm   = (origin.z - frustum_corner.w) / (frustum_corner.z - frustum_corner.w);
  	vec3  normal   = texture(normal_sampler, var_texcoord0).xyz * 2.0 - 1.0;
    float rotation = hash(var_texcoord0) * 6.28;
    float r        = radius / abs(origin.z);
    float rStart   = r * z_norm * bias_dist;
    float rStep    = (r - rStart) / samples;
    float ao       = 0.0;

    for (int i = 0; i < samples; ++i, rotation += goldenAngle) {
        vec2  offsetUV    = var_texcoord0 + vec2(sin(rotation), cos(rotation)) * (rStart + rStep * (i + 1));
        float offsetDepth = texture(depth_buffer, offsetUV).r;
        float offsetZ     = linearizeDepth(offsetDepth);
        vec3  offset      = viewPosFromLinearDepth(offsetZ, offsetUV);

        vec3  diff      = offset - origin;
        float fadeout   = 1.0 - smoothstep(min_distance, max_distance, length(diff) * attenuation);
        float incidence = smoothstep(bias_angle, 1.0, dot(normal, normalize(diff)));
        ao += incidence * fadeout;
    }

	frag_color = vec4(1.0 - ao / samples * intensity);
}
