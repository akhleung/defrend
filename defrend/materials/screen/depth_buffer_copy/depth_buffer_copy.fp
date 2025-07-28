#version 420
#extension GL_ARB_shading_language_include : require

#include "/defrend/include/lighting_functions.glsl"

in vec2 var_texcoord0;

uniform sampler2D depth_buffer;

layout(location = 0) out vec4 fragColor;

void main() {
	fragColor = float_to_rgba(texture(depth_buffer, var_texcoord0).r);
}
