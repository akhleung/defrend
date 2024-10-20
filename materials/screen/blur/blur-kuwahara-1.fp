#version 420 core

in vec2 var_texcoord0;

uniform sampler2D ssao_sampler;

uniform blur_fp {
	vec4 resolution;
};

out vec4 frag_color;

int radius = 2;
vec3 offset = vec3(0);

float random (vec4 seed4) {
    float dot_product = dot(seed4, vec4(12.9898,78.233,45.164,94.673));
    return fract(sin(dot_product) * 43758.5453);
}

void main() {
	// // vec2 texelSize = 1.0 / textureSize(ssao_sampler, 0);
	// vec4 ssao = vec4(0.0);
	// for (int i = 0; i < 4; i++) {
	// 	ssao += texture(ssao_sampler, var_texcoord0 + (random(vec4(var_texcoord0, -var_texcoord0) * vec4(float(-i))) / 200.0));
	// 	// ssao += texture(ssao_sampler, var_texcoord0 + (random(vec4(-var_texcoord0, var_texcoord0) * vec4(float(i)))/100.0));
	// }
	// // ssao /= 8.0;
	// ssao /= 4.0;
	// frag_color.g = ssao.g;

    vec2 src_size = vec2 ( resolution.x,  resolution.y);
    vec2 uv = var_texcoord0.xy;
    float n = float((radius + 1) * (radius + 1));
    vec3 m0 = offset; vec3 m1 = offset; vec3 m2 = offset; vec3 m3 = offset;
    vec3 s0 = offset; vec3 s1 = offset; vec3 s2 = offset; vec3 s3 = offset;
    vec3 c;

    for (int j = -radius; j <= 0; ++j)  {
        for (int i = -radius; i <= 0; ++i)  {
            c = texture(ssao_sampler, uv + vec2(float(i),float(j)) * src_size).rgb;
            m0 += c;
            s0 += c * c;
        }
    }

    for (int j = -radius; j <= 0; ++j)  {
        for (int i = 0; i <= radius; ++i)  {
            c = texture(ssao_sampler, uv + vec2(float(i),float(j)) * src_size).rgb;
            m1 += c;
            s1 += c * c;
        }
    }

    for (int j = 0; j <= radius; ++j)  {
        for (int i = 0; i <= radius; ++i)  {
            c = texture(ssao_sampler, uv + vec2(float(i),float(j)) * src_size).rgb;
            m2 += c;
            s2 += c * c;
        }
    }

	for (int j = 0; j <= radius; ++j)  {
		for (int i = -radius; i <= 0; ++i)  {
			c = texture(ssao_sampler, uv + vec2(float(i),float(j)) * src_size).rgb;
			m3 += c;
			s3 += c * c;
		}
	}

	float min_sigma2 = 1e+2;
	m0 /= n;
	s0 = abs(s0 / n - m0 * m0);

	float sigma2 = s0.r + s0.g + s0.b;
	if (sigma2 < min_sigma2) {
		min_sigma2 = sigma2;
		frag_color = vec4(m0, 1.0);
	}

	m1 /= n;
	s1 = abs(s1 / n - m1 * m1);

	sigma2 = s1.r + s1.g + s1.b;
	if (sigma2 < min_sigma2) {
		min_sigma2 = sigma2;
		frag_color = vec4(m1, 1.0);
	}

	m2 /= n;
	s2 = abs(s2 / n - m2 * m2);

	sigma2 = s2.r + s2.g + s2.b;
	if (sigma2 < min_sigma2) {
		min_sigma2 = sigma2;
		frag_color = vec4(m2, 1.0);
	}

	m3 /= n;
	s3 = abs(s3 / n - m3 * m3);

	sigma2 = s3.r + s3.g + s3.b;
	if (sigma2 < min_sigma2) {
		min_sigma2 = sigma2;
		frag_color = vec4(m3, 1.0);
	}
}
