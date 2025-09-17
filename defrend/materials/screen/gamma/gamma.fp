#version 420 core

in vec2 var_texcoord0;

uniform sampler2D color_sampler;

uniform gamma_fp {
    vec4 params;
};

float gamma = params.x;

layout(location = 0) out vec4 frag_color;

void main() {
    vec4 color = texture(color_sampler, var_texcoord0);
    frag_color = vec4(pow(color.rgb, vec3(1 / gamma)), color.a);
}
