local settings = require "defrend.render.settings"
local uniforms = require "defrend.render.uniforms"

return function (self)
	local changed, checked = imgui.checkbox("Enabled", settings.dual_kawase_blur.enabled)
	if changed then
		settings.dual_kawase_blur.enabled = checked
	end

	local changed, value = imgui.input_float("Separation", settings.dual_kawase_blur.separation, 0.1, 0.5)
	if changed then
		settings.dual_kawase_blur.separation = vmath.clamp(value, 0, 10)
		uniforms_changed = true
	end

    local changed, value = imgui.input_float("Strength", settings.dual_kawase_blur.strength, 0.01, 0.1)
	if changed then
		settings.dual_kawase_blur.strength = vmath.clamp(value, 0, 5)
		uniforms_changed = true
	end

	if uniforms_changed then
		uniforms.dual_kawase_blur.init()
        uniforms_changed = false
	end

	imgui.spacing()
end
