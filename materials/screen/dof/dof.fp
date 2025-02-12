#version 420

uniform sampler2D depth_buffer;
uniform sampler2D color_sampler;

uniform dof_fp {
	vec4 params1;
	vec4 params2;
	vec4 frustum_terms;
};

vec2 resolution = vec2(params1.x, params1.y);
float focal_depth = params2.x;
float blur_start = params2.y;
float blur_full = params2.z;
float radius = params2.w;

out vec4 fragColor;

float linearizeDepth(float d) {
    float zNdc  = 2.0 * d - 1.0;
    return 2.0 * frustum_terms.x / (frustum_terms.y - zNdc * (frustum_terms.z));
}

void main() {
	vec2 texcoord = gl_FragCoord.xy / resolution;
	// write out depth buffer for testing / debugging for now
	vec4 color = texture(color_sampler, texcoord);
	float d = texture(depth_buffer, texcoord).r;
	fragColor = vec4(d, d, d, clamp(color.a * 100, 1, 1));
	return;
	// float z = linearizeDepth(texture(depth_buffer, texcoord).r);
	// float blur = abs(focal_depth - z);
	// float r = smoothstep(blur, blur_start, blur_full) * radius;
	// int samples = int(clamp(ceil(r), 0, 1));
	// float count = pow(2 * samples + 1, 2);
	// for (int i = -samples; i <= 1; ++samples) {
	// 	for (int j = -samples; j <= 1; ++samples) {
	// 		fragColor += texture(color_sampler, (gl_FragCoord.xy + (vec2(i, j) * r)) / resolution);
	// 	}
	// }
	// fragColor = count <= 1 ? texture(color_sampler1, texcoord) : fragColor / count;
}
