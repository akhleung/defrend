local settings = require "defrend.render.settings"
local uniforms = require "defrend.render.uniforms"

return function (self)
	local uniforms_changed = false

	local changed, checked = imgui.checkbox("Enabled", settings.bloom.enabled)
	if changed then
		settings.bloom.enabled = checked
	end

	local changed, value = imgui.input_float("Threshold", settings.bloom.threshold, 0.01, 0.05)
	if changed then
		settings.bloom.threshold = vmath.clamp(value, 0, 1)
		uniforms_changed = true
	end

	local changed, value = imgui.input_int("Radius", settings.bloom.radius)
	if changed then
		settings.bloom.radius = vmath.clamp(value, 1, 16)
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Separation", settings.bloom.separation, 0.5, 1.0)
	if changed then
		settings.bloom.separation = vmath.clamp(value, 1, 16)
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Strength", settings.bloom.strength, 0.05, 0.1)
	if changed then
		settings.bloom.strength = vmath.clamp(value, 0, 1)
		uniforms_changed = true
	end

	if uniforms_changed then
		uniforms.bloom.init()
        uniforms_changed = false
	end

	imgui.spacing()
end
