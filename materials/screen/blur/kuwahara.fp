#version 420

#define MAX_SIZE        5
#define MAX_KERNEL_SIZE ((MAX_SIZE * 2 + 1) * (MAX_SIZE * 2 + 1))

uniform sampler2D color_sampler;
uniform blur_fp {
    vec4 params;
};

out vec4 fragColor;

int samples = int(params.z);
vec2 texSize  = params.xy;
vec2 texCoord = gl_FragCoord.xy / texSize;

int i     = 0;
int j     = 0;
int count = 0;

vec3  valueRatios = vec3(0.3, 0.59, 0.11);

float values[MAX_KERNEL_SIZE];

vec4  color       = vec4(0.0);
vec4  meanTemp    = vec4(0.0);
vec4  mean        = vec4(0.0);
float valueMean   =  0.0;
float variance    =  0.0;
float minVariance = -1.0;

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

    meanTemp.rgb /= count;
    valueMean     = dot(meanTemp.rgb, valueRatios);

    for (i = 0; i < count; ++i) {
        variance += pow(values[i] - valueMean, 2);
    }

    variance /= count;

    if (variance < minVariance || minVariance <= -1) {
        mean = meanTemp;
        minVariance = variance;
    }
}

void main() {
    fragColor = texture(color_sampler, texCoord);

    if (samples <= 0) return;

    findMean(-samples, 0, -samples, 0); // Lower Left
    findMean(0, samples, 0, samples); // Upper Right
    findMean(-samples, 0, 0, samples); // Upper Left
    findMean(0, samples, -samples, 0); // Lower Right

    fragColor.rgb = mean.rgb;
}