bool is_focused(float coc, float focused_coc_threshold) {
	return abs(coc) <= focused_coc_threshold;
}

bool is_foreground(float coc, float focused_coc_threshold) {
	return coc > focused_coc_threshold;
}

bool is_background(float coc, float focused_coc_threshold) {
	return coc < -focused_coc_threshold;
}

vec4 visualize_coc(float coc) {
	if (coc < 0) {
		return vec4(abs(coc), 0, 0, 1.0);
	} else {
		return vec4(0, 0, abs(coc), 1.0);
	}
}