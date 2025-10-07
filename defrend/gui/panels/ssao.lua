local settings = require "defrend.render.settings"
local uniforms = require "defrend.render.uniforms"

return function (self)
	local uniforms_changed = false

	local changed, checked = imgui.checkbox("Enabled", settings.ssao.enabled)
	if changed then
		settings.ssao.enabled = checked
	end
	local changed, checked = imgui.checkbox("Blur", settings.ssao.blur)
	if changed then
		settings.ssao.blur = checked
	end

	local changed, value = imgui.input_float("Viewport scale", settings.ssao.scale, 0.1, 0.1)
	if changed then
		settings.ssao.scale = vmath.clamp(value, 0.1, 1.0)
		uniforms_changed = true
	end

	local changed, value = imgui.input_int("Samples", settings.ssao.samples)
	if changed then
		settings.ssao.samples = vmath.clamp(value, 4, 64)
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Intensity", settings.ssao.intensity, 0.05, 0.1)
	if changed then
		settings.ssao.intensity = vmath.clamp(value, 0.1, 10)
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Bias angle", settings.ssao.bias_angle, 0.05, 0.1)
	if changed then
		settings.ssao.bias_angle = vmath.clamp(value, 0.0, 1.0)
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Bias distance", settings.ssao.bias_dist, 0.05, 0.1)
	if changed then
		settings.ssao.bias_dist = vmath.clamp(value, 0.0, 1.0)
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Min distance", settings.ssao.min_distance, 0.05, 0.5)
	if changed then
		settings.ssao.min_distance = vmath.clamp(value, 0.0, 50)
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Max distance", settings.ssao.max_distance, 0.05, 0.5)
	if changed then
		if value <= settings.ssao.min_distance then
			value = settings.ssao.min_distance + 0.1
		end
		settings.ssao.max_distance = vmath.clamp(value, 0.1, 50)
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Attenuation", settings.ssao.attenuation, 0.05, 0.5)
	if changed then
		settings.ssao.attenuation = vmath.clamp(value, 0.0, 50)
		uniforms_changed = true
	end
	local changed, value = imgui.input_float("Radius", settings.ssao.radius, 0.05, 0.5)
	if changed then
		settings.ssao.radius = vmath.clamp(value, 0.1, 50)
		uniforms_changed = true
	end

	if uniforms_changed then
		uniforms.ssao.init()
        uniforms_changed = false
	end

	imgui.spacing()
end
