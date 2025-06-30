#version 320 es

#define MAX_SIZE        5
#define MAX_KERNEL_SIZE ((MAX_SIZE + 1) * (MAX_SIZE + 1))

uniform sampler2D color_sampler;
uniform blur_fp {
    mediump vec4 params;
};

out mediump vec4 fragColor;

int samples;
mediump vec2 texSize;
mediump vec2 texCoord;

int i     = 0;
int j     = 0;
int count = 0;

mediump vec3  valueRatios;

mediump float values[MAX_KERNEL_SIZE];

mediump vec4  color       = vec4(0.0);
mediump vec4  meanTemp    = vec4(0.0);
mediump vec4  mean        = vec4(0.0);
mediump float valueMean   =  0.0;
mediump float variance    =  0.0;
mediump float minVariance = -1.0;

void findMean(int i0, int i1, int j0, int j1) {
    meanTemp = vec4(0);
    count    = 0;

    for (i = i0; i <= i1; ++i) {
        for (j = j0; j <= j1; ++j) {
            color = texture(color_sampler, (gl_FragCoord.xy + vec2(i, j)) / texSize);
            meanTemp += color;
            values[count] = dot(color.rgb, valueRatios);
            ++count;
        }
    }

    meanTemp.rgb /= float(count);
    valueMean     = dot(meanTemp.rgb, valueRatios);

    for (i = 0; i < count; ++i) {
        variance += pow(values[i] - valueMean, 2.0);
    }

    variance /= float(count);

    if (variance < minVariance || minVariance <= -1.0) {
        mean = meanTemp;
        minVariance = variance;
    }
}

void main() {

    samples = int(params.z);
    texSize  = params.xy;
    texCoord = gl_FragCoord.xy / texSize;
    valueRatios = vec3(0.3, 0.59, 0.11);

    fragColor = texture(color_sampler, texCoord);

    if (samples <= 0) return;

    findMean(-samples, 0, -samples, 0); // Lower Left
    findMean(0, samples, 0, samples); // Upper Right
    findMean(-samples, 0, 0, samples); // Upper Left
    findMean(0, samples, -samples, 0); // Lower Right

    fragColor.rgb = mean.rgb;
}