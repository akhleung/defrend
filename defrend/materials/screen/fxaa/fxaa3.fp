#version 320 es

in mediump vec2 var_texcoord0;

uniform fxaa_fp {
	mediump vec4 params;
};

uniform sampler2D color_sampler;

out mediump vec4 fragColor;

// Settings for FXAA.
#define EDGE_THRESHOLD_MIN 0.0312
#define EDGE_THRESHOLD_MAX 0.125
#define QUALITY(q) ((q) < 5 ? 1.0 : ((q) > 5 ? ((q) < 10 ? 2.0 : ((q) < 11 ? 4.0 : 8.0)) : 1.5))
#define ITERATIONS 12
#define SUBPIXEL_QUALITY 0.75

/** Evalute the luma value in perceptual space for a given RGB color in linear space.
\param rgb the input RGB color
\return the perceptual luma
*/
mediump float rgb2luma (mediump vec3 rgb) {
	return sqrt(dot(rgb, vec3(0.299, 0.587, 0.114)));
}

/** Performs FXAA post-process anti-aliasing as described in the Nvidia FXAA white paper and the associated shader code.
*/
void main() {
	mediump vec2 texel = 1.0 / params.xy;

	mediump vec4 colorCenterFull = texture(color_sampler, var_texcoord0);
	mediump vec3 colorCenter = colorCenterFull.rgb;
	
	// Luma at the current fragment
	mediump float lumaCenter = rgb2luma(colorCenter);
	
	// Luma at the four direct neighbours of the current fragment.
	mediump float lumaDown 	= rgb2luma(texture(color_sampler, var_texcoord0 - vec2(0, texel.y)).rgb);
	mediump float lumaUp 	= rgb2luma(texture(color_sampler, var_texcoord0 + vec2(0, texel.y)).rgb);
	mediump float lumaLeft 	= rgb2luma(texture(color_sampler, var_texcoord0 - vec2(texel.x, 0)).rgb);
	mediump float lumaRight = rgb2luma(texture(color_sampler, var_texcoord0 + vec2(texel.x, 0)).rgb);
	
	// Find the maximum and minimum luma around the current fragment.
	mediump float lumaMin = min(lumaCenter, min(min(lumaDown, lumaUp), min(lumaLeft, lumaRight)));
	mediump float lumaMax = max(lumaCenter, max(max(lumaDown, lumaUp), max(lumaLeft, lumaRight)));
	
	// Compute the delta.
	mediump float lumaRange = lumaMax - lumaMin;
	
	// If the luma variation is lower that a threshold (or if we are in a really dark area), we are not on an edge, don't perform any AA.
	if (lumaRange < max(EDGE_THRESHOLD_MIN, lumaMax * EDGE_THRESHOLD_MAX)) {
		fragColor = colorCenterFull;
		// fragColor = vec4(1, 1, 1, 1);
		return;
	}
	
	// Query the 4 remaining corners' lumas.
	mediump float lumaDownLeft 	= rgb2luma(texture(color_sampler, var_texcoord0 - texel).rgb);
	mediump float lumaUpRight 	= rgb2luma(texture(color_sampler, var_texcoord0 + texel).rgb);
	mediump float lumaUpLeft 	= rgb2luma(texture(color_sampler, var_texcoord0 + vec2(-texel.x, texel.y)).rgb);
	mediump float lumaDownRight = rgb2luma(texture(color_sampler, var_texcoord0 + vec2(texel.x, -texel.y)).rgb);
	
	// Combine the four edges' lumas (using intermediary variables for future computations with the same values).
	mediump float lumaDownUp = lumaDown + lumaUp;
	mediump float lumaLeftRight = lumaLeft + lumaRight;
	
	// Same for corners
	mediump float lumaLeftCorners = lumaDownLeft + lumaUpLeft;
	mediump float lumaDownCorners = lumaDownLeft + lumaDownRight;
	mediump float lumaRightCorners = lumaDownRight + lumaUpRight;
	mediump float lumaUpCorners = lumaUpRight + lumaUpLeft;
	
	// Compute an estimation of the gradient along the horizontal and vertical axis.
	mediump float edgeHorizontal =	abs(-2.0 * lumaLeft + lumaLeftCorners)	+ abs(-2.0 * lumaCenter + lumaDownUp ) * 2.0	+ abs(-2.0 * lumaRight + lumaRightCorners);
	mediump float edgeVertical =	abs(-2.0 * lumaUp + lumaUpCorners)		+ abs(-2.0 * lumaCenter + lumaLeftRight) * 2.0	+ abs(-2.0 * lumaDown + lumaDownCorners);
	
	// Is the local edge horizontal or vertical ?
	bool isHorizontal = (edgeHorizontal >= edgeVertical);
	
	// Choose the step size (one pixel) accordingly.
	mediump float stepLength = isHorizontal ? texel.y : texel.x;
	
	// Select the two neighboring texels lumas in the opposite direction to the local edge.
	mediump float luma1 = isHorizontal ? lumaDown : lumaLeft;
	mediump float luma2 = isHorizontal ? lumaUp : lumaRight;
	// Compute gradients in this direction.
	mediump float gradient1 = luma1 - lumaCenter;
	mediump float gradient2 = luma2 - lumaCenter;
	
	// Which direction is the steepest ?
	bool is1Steepest = abs(gradient1) >= abs(gradient2);
	
	// Gradient in the corresponding direction, normalized.
	mediump float gradientScaled = 0.25*max(abs(gradient1),abs(gradient2));
	
	// Average luma in the correct direction.
	mediump float lumaLocalAverage = 0.0;
	if (is1Steepest) {
		// Switch the direction
		stepLength = -stepLength;
		lumaLocalAverage = 0.5 * (luma1 + lumaCenter);
	} else {
		lumaLocalAverage = 0.5 * (luma2 + lumaCenter);
	}
	
	// Shift UV in the correct direction by half a pixel.
	mediump vec2 currentUv = var_texcoord0;
	if (isHorizontal) {
		currentUv.y += stepLength * 0.5;
	} else {
		currentUv.x += stepLength * 0.5;
	}
	
	// Compute offset (for each iteration step) in the right direction.
	mediump vec2 offset = isHorizontal ? vec2(texel.x, 0.0) : vec2(0.0, texel.y);
	// Compute UVs to explore on each side of the edge, orthogonally. The QUALITY allows us to step faster.
	mediump vec2 uv1 = currentUv - offset * QUALITY(0);
	mediump vec2 uv2 = currentUv + offset * QUALITY(0);
	
	// Read the lumas at both current extremities of the exploration segment, and compute the delta wrt to the local average luma.
	mediump float lumaEnd1 = rgb2luma(texture(color_sampler, uv1).rgb);
	mediump float lumaEnd2 = rgb2luma(texture(color_sampler, uv2).rgb);
	lumaEnd1 -= lumaLocalAverage;
	lumaEnd2 -= lumaLocalAverage;
	
	// If the luma deltas at the current extremities is larger than the local gradient, we have reached the side of the edge.
	bool reached1 = abs(lumaEnd1) >= gradientScaled;
	bool reached2 = abs(lumaEnd2) >= gradientScaled;
	bool reachedBoth = reached1 && reached2;
	
	// If the side is not reached, we continue to explore in this direction.
	if (!reached1) {
		uv1 -= offset * QUALITY(1);
	}
	if (!reached2) {
		uv2 += offset * QUALITY(1);
	}
	
	// If both sides have not been reached, continue to explore.
	if (!reachedBoth) {
		
		for (int i = 2; i < ITERATIONS; i++) {
			// If needed, read luma in 1st direction, compute delta.
			if (!reached1) {
				lumaEnd1 = rgb2luma(texture(color_sampler, uv1).rgb);
				lumaEnd1 = lumaEnd1 - lumaLocalAverage;
			}
			// If needed, read luma in opposite direction, compute delta.
			if (!reached2) {
				lumaEnd2 = rgb2luma(texture(color_sampler, uv2).rgb);
				lumaEnd2 = lumaEnd2 - lumaLocalAverage;
			}
			// If the luma deltas at the current extremities is larger than the local gradient, we have reached the side of the edge.
			reached1 = abs(lumaEnd1) >= gradientScaled;
			reached2 = abs(lumaEnd2) >= gradientScaled;
			reachedBoth = reached1 && reached2;
			
			// If the side is not reached, we continue to explore in this direction, with a variable quality.
			if (!reached1) {
				uv1 -= offset * QUALITY(i);
			}
			if (!reached2) {
				uv2 += offset * QUALITY(i);
			}
			
			// If both sides have been reached, stop the exploration.
			if (reachedBoth) { break; }
		}
		
	}
	
	// Compute the distances to each side edge of the edge (!).
	mediump float distance1 = isHorizontal ? (var_texcoord0.x - uv1.x) : (var_texcoord0.y - uv1.y);
	mediump float distance2 = isHorizontal ? (uv2.x - var_texcoord0.x) : (uv2.y - var_texcoord0.y);
	
	// In which direction is the side of the edge closer ?
	bool isDirection1 = distance1 < distance2;
	mediump float distanceFinal = min(distance1, distance2);
	
	// Thickness of the edge.
	mediump float edgeThickness = (distance1 + distance2);
	
	// Is the luma at center smaller than the local average ?
	bool isLumaCenterSmaller = lumaCenter < lumaLocalAverage;
	
	// If the luma at center is smaller than at its neighbour, the delta luma at each end should be positive (same variation).
	bool correctVariation1 = (lumaEnd1 < 0.0) != isLumaCenterSmaller;
	bool correctVariation2 = (lumaEnd2 < 0.0) != isLumaCenterSmaller;
	
	// Only keep the result in the direction of the closer side of the edge.
	bool correctVariation = isDirection1 ? correctVariation1 : correctVariation2;
	
	// UV offset: read in the direction of the closest side of the edge.
	mediump float pixelOffset = - distanceFinal / edgeThickness + 0.5;
	
	// If the luma variation is incorrect, do not offset.
	mediump float finalOffset = correctVariation ? pixelOffset : 0.0;
	
	// Sub-pixel shifting
	// Full weighted average of the luma over the 3x3 neighborhood.
	mediump float lumaAverage = (1.0 / 12.0) * (2.0 * (lumaDownUp + lumaLeftRight) + lumaLeftCorners + lumaRightCorners);
	// Ratio of the delta between the global average and the center luma, over the luma range in the 3x3 neighborhood.
	mediump float subPixelOffset1 = clamp(abs(lumaAverage - lumaCenter) / lumaRange, 0.0, 1.0);
	mediump float subPixelOffset2 = (-2.0 * subPixelOffset1 + 3.0) * subPixelOffset1 * subPixelOffset1;
	// Compute a sub-pixel offset based on this delta.
	mediump float subPixelOffsetFinal = subPixelOffset2 * subPixelOffset2 * SUBPIXEL_QUALITY;
	
	// Pick the biggest of the two offsets.
	finalOffset = max(finalOffset, subPixelOffsetFinal);
	
	// Compute the final UV coordinates.
	mediump vec2 finalUv = var_texcoord0;
	if (isHorizontal) {
		finalUv.y += finalOffset * stepLength;
	} else {
		finalUv.x += finalOffset * stepLength;
	}
	
	// Read the color at the new UV coordinates, and use it.
	mediump vec4 finalColor = texture(color_sampler, finalUv);
	fragColor = finalColor;
}