local settings = require "defrend.render.settings"
local uniforms = require "defrend.render.uniforms"

return function (self)
	local uniforms_changed = false

	local changed, checked = imgui.checkbox("Enabled", settings.glow.enabled)
	if changed then
		settings.glow.enabled = checked
	end

	local changed, checked = imgui.checkbox("Downsample", settings.glow.downsample)
	if changed then
		settings.glow.downsample = checked
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Separation", settings.glow.separation, 0.1, 0.5)
	if changed then
		settings.glow.separation = vmath.clamp(value, 0, 1.5)
		uniforms_changed = true
	end

	if uniforms_changed then
		uniforms.glow.init()
        uniforms_changed = false
	end

	imgui.spacing()
end
