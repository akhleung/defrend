local settings = require "defrend.render.settings"
local uniforms = require "defrend.render.uniforms"

return function (self)
	local uniforms_changed = false

	local changed, checked = imgui.checkbox("Enabled", settings.dilate.enabled)
	if changed then
		settings.dilate.enabled = checked
	end

	local changed, value = imgui.input_float("Min threshold", settings.dilate.min_threshold, 0.05, 0.1)
	if changed then
		settings.dilate.min_threshold = vmath.clamp(value, 0, settings.dilate.max_threshold - 0.05)
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Max threshold", settings.dilate.max_threshold, 0.05, 0.1)
	if changed then
		settings.dilate.max_threshold = vmath.clamp(value, settings.dilate.min_threshold + 0.05, 1)
		uniforms_changed = true
	end

	local changed, value = imgui.input_int("Radius", settings.dilate.radius)
	if changed then
		settings.dilate.radius = vmath.clamp(value, 0, 16)
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Separation", settings.dilate.separation, 0.5, 1.0)
	if changed then
		settings.dilate.separation = vmath.clamp(value, 1, 16)
		uniforms_changed = true
	end

	if uniforms_changed then
		uniforms.dilate.init()
	end
end
