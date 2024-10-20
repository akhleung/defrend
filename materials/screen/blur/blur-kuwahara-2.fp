// varying mediump vec4 position;
// varying mediump vec2 var_texcoord0;

// uniform lowp sampler2D texture_sampler;
// uniform lowp vec4 tint;

// void main()
// {
// 	// Pre-multiply alpha since all runtime textures already are
// 	lowp vec4 tint_pm = vec4(tint.xyz * tint.w, tint.w);
// 	gl_FragColor = texture2D(texture_sampler, var_texcoord0.xy) * tint_pm;
// }

/*
  (C) 2019 David Lettier
  lettier.com
*/

#version 150

#define MAX_SIZE        5
#define MAX_KERNEL_SIZE ((MAX_SIZE * 2 + 1) * (MAX_SIZE * 2 + 1))

uniform sampler2D colorTexture;

uniform vec2 parameters;

out vec4 fragColor;

vec2 texSize  = textureSize(colorTexture, 0).xy;
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
      color = texture(colorTexture, (gl_FragCoord.xy + vec2(i, j)) / texSize);
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
  fragColor = texture(colorTexture, texCoord);

  int size = int(parameters.x);
  if (size <= 0) { return; }

  findMean(-size, 0, -size, 0); // Lower Left
  findMean(0, size, 0, size); // Upper Right
  findMean(-size, 0, 0, size); // Upper Left
  findMean(0, size, -size, 0); // Lower Right

  fragColor.rgb = mean.rgb;
}