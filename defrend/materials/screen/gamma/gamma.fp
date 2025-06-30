#version 320 es

in mediump vec2 var_texcoord0;

uniform sampler2D color_sampler;

uniform gamma_fp {
    mediump vec4 params;
};

out mediump vec4 frag_color;

void main() {
    mediump float gamma = params.x;
    mediump vec4 color = texture(color_sampler, var_texcoord0);
    frag_color = vec4(pow(color.rgb, vec3(1.0 / gamma)), 1.0);
}
