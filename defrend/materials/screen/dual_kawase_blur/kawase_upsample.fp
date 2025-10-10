#version 420
precision highp float;

in vec2 var_texcoord0;

uniform sampler2D color_sampler;

uniform kawase_upsample_fp {
	vec4 params;
};

vec2 resolution = textureSize(color_sampler, 0);
float iteration = params.x;
float separation = params.y;
float bloom = params.z;
vec2 corner = vec2(0.5) * separation / resolution;
vec2 top = vec2(0, corner.y) * 2;
vec2 right = vec2(corner.x, 0) * 2;

layout(location = 0) out vec4 fragColor;

void main() {
	vec4 color = vec4(0);
	color += texture(color_sampler, var_texcoord0 - right);
	color += texture(color_sampler, var_texcoord0 + right);
	color += texture(color_sampler, var_texcoord0 + top);
	color += texture(color_sampler, var_texcoord0 - top);
	color += texture(color_sampler, var_texcoord0 + vec2(-corner.x, corner.y)) * 2;
	color += texture(color_sampler, var_texcoord0 + corner) * 2;
	color += texture(color_sampler, var_texcoord0 - corner) * 2;
	color += texture(color_sampler, var_texcoord0 + vec2(corner.x, -corner.y)) * 2;
	fragColor = (color / 12.0) * bloom;
}
