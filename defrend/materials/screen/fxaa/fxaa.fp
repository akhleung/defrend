#version 420 core

in vec2 var_texcoord0;

uniform fxaa_fp {
	vec4 params;
};

uniform sampler2D color_sampler;

out vec4 frag_color;

float reducemul = 0.125;
float reducemin = 0.0078125;
vec3 luma = vec3(0.299, 0.587, 0.114);
vec2 u_texel = 1.0 / params.xy;
float u_strength = params.z;

void main() {
    
    vec3 basecol = texture(color_sampler, var_texcoord0).rgb;
    vec3 baseNW = texture(color_sampler, var_texcoord0 - u_texel).rgb;
    vec3 baseNE = texture(color_sampler, var_texcoord0 + vec2(u_texel.x, -u_texel.y)).rgb;
    vec3 baseSW = texture(color_sampler, var_texcoord0 + vec2(-u_texel.x, u_texel.y)).rgb;
    vec3 baseSE = texture(color_sampler, var_texcoord0 + u_texel).rgb;
    
    float lumacol = dot(basecol, luma);
    float lumaNW = dot(baseNW, luma);
    float lumaNE = dot(baseNE, luma);
    float lumaSW = dot(baseSW, luma);
    float lumaSE = dot(baseSE, luma);
    
    float lumamin = min(lumacol, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
    float lumamax = max(lumacol, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));
    
    vec2 dir = vec2(-((lumaNW + lumaNE) - (lumaSW + lumaSE)), ((lumaNW + lumaSW) - (lumaNE + lumaSE)));
    float dirreduce = max((lumaNW + lumaNE + lumaSW + lumaSE) * reducemul * 0.25, reducemin);
    float dirmin = 1.0 / (min(abs(dir.x), abs(dir.y)) + dirreduce);
    dir = min(vec2(u_strength), max(vec2(-u_strength), dir * dirmin)) * u_texel;
    
    vec4 resultA = 0.5 * (texture(color_sampler, var_texcoord0 + dir * -0.166667) +
                          texture(color_sampler, var_texcoord0 + dir * 0.166667));
    vec4 resultB = resultA * 0.5 + 0.25 * (texture(color_sampler, var_texcoord0 + dir * -0.5) +
                                           texture(color_sampler, var_texcoord0 + dir * 0.5));
    float lumaB = dot(resultB.rgb, luma);
    
    if (lumaB < lumamin || lumaB > lumamax) {
        frag_color = resultA;
    } else {
        frag_color = resultB;
    }
}
