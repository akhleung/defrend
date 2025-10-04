local settings = require "defrend.render.settings"
local uniforms = require "defrend.render.uniforms"

return function (self)
	local uniforms_changed = false

	local changed, checked = imgui.checkbox("Enabled", settings.fxaa.enabled)
	if changed then
		settings.fxaa.enabled = checked
	end

	local changed, value = imgui.input_int("Iterations", settings.fxaa.iterations)
	if changed then
		settings.fxaa.iterations = vmath.clamp(value, 3, 32)
		uniforms_changed = true
	end

	if uniforms_changed then
		uniforms.fxaa.init()
	end

	imgui.spacing()
end
