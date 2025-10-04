local settings = require "defrend.render.settings"
local uniforms = require "defrend.render.uniforms"

return function (self)
	local uniforms_changed = false

	local changed, checked = imgui.checkbox("Enabled", settings.dof.enabled)
	if changed then
		settings.dof.enabled = checked
	end

	local changed, value = imgui.input_float("Focal depth", settings.dof.focal_depth, 1.0, 5.0)
	if changed then
		if value < 0 then
			value = 0
		end
		settings.dof.focal_depth = value
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Blur start", settings.dof.blur_start, 1.0, 5.0)
	if changed then
		settings.dof.blur_start = vmath.clamp(value, 0, settings.dof.blur_full - 1)
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Blur full", settings.dof.blur_full, 1.0, 5.0)
	if changed then
		settings.dof.blur_full = vmath.clamp(value, settings.dof.blur_start + 1, 2000000000)
		uniforms_changed = true
	end

	if uniforms_changed then
		uniforms.dof.init()
	end

	imgui.spacing()
end
