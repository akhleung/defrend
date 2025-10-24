#version 420
precision highp float;

in vec2 var_texcoord0;

uniform sampler2D color_sampler;

uniform kawase_downsample_fp {
	vec4 params;
};

vec2 resolution = textureSize(color_sampler, 0);
float separation = params.x;
float bloom = params.y;
vec2 offset = vec2(0.5) * separation / resolution;

layout(location = 0) out vec4 fragColor;

void main() {
	vec4 color = texture(color_sampler, var_texcoord0) * 4.0;
	color += texture(color_sampler, var_texcoord0 + vec2(-offset.x, offset.y));
	color += texture(color_sampler, var_texcoord0 + offset);
	color += texture(color_sampler, var_texcoord0 - offset);
	color += texture(color_sampler, var_texcoord0 + vec2(offset.x, -offset.y));
	fragColor = (color / 8.0) * bloom;
}
