local settings = require "defrend.render.settings"
local uniforms = require "defrend.render.uniforms"

return function (self)
	local uniforms_changed = false

	local changed, checked = imgui.checkbox("Enabled", settings.glow.enabled)
	if changed then
		settings.glow.enabled = checked
	end

	local changed, value = imgui.input_float("Radius", settings.glow.radius, 0.5, 1.0)
	if changed then
		settings.glow.radius = vmath.clamp(value, 0, 10)
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Separation", settings.glow.separation, 0.5, 1.0)
	if changed then
		settings.glow.separation = vmath.clamp(value, 1, 10)
		uniforms_changed = true
	end

	if uniforms_changed then
		uniforms.glow.init()
	end
end
