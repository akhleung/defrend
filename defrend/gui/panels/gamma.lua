local settings = require "defrend.render.settings"
local uniforms = require "defrend.render.uniforms"

return function (self)
	local uniforms_changed = false

	local changed, checked = imgui.checkbox("Enabled", settings.gamma.enabled)
	if changed then
		settings.gamma.enabled = checked
	end

	local changed, value = imgui.input_float("Gamma", settings.gamma.gamma, 0.1, 0.2)
	if changed then
		settings.gamma.gamma = vmath.clamp(value, 1, 10)
		uniforms_changed = true
	end

	if uniforms_changed then
		uniforms.gamma.init()
        uniforms_changed = false
	end

	imgui.spacing()
end
