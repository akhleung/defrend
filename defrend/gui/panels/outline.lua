local settings = require "defrend.render.settings"
local uniforms = require "defrend.render.uniforms"

return function (self)
	local uniforms_changed = false

	local changed, checked = imgui.checkbox("Enabled", settings.outline.enabled)
	if changed then
		settings.outline.enabled = checked
	end

	local new_outline_color = vmath.vector4(settings.outline.outline_color)
	imgui.color_edit4("Outline color", new_outline_color, imgui.COLOREDITFLAGS_ALPHABAR)
	if new_outline_color ~= settings.outline.outline_color then
		settings.outline.outline_color = new_outline_color
		uniforms_changed = true
	end

	imgui.separator()
	imgui.text("Outline detection:")

	local changed, value = imgui.input_float("Depth threshold", settings.outline.depth_threshold, 0.001, 0.005)
	if changed then
		settings.outline.depth_threshold = vmath.clamp(value, 0, 1)
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Normal threshold", settings.outline.normal_threshold, 0.05, 0.1)
	if changed then
		settings.outline.normal_threshold = vmath.clamp(value, 0, 1)
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Normal smoothing", settings.outline.normal_smoothing, 0.05, 0.1)
	if changed then
		settings.outline.normal_smoothing = vmath.clamp(value, 0, 1)
		uniforms_changed = true
	end

	imgui.separator()
	imgui.text("Outline thickness:")

	local changed, value = imgui.input_float("Min thickness", settings.outline.min_thickness, 0.05, 0.1)
	if changed then
		settings.outline.min_thickness = vmath.clamp(value, 0, settings.outline.max_thickness - 0.05)
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Max thickness", settings.outline.max_thickness, 0.05, 0.1)
	if changed then
		settings.outline.max_thickness = vmath.clamp(value, settings.outline.min_thickness + 0.05, 10)
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Min distance", settings.outline.min_distance, 0.1, 0.5)
	if changed then
		settings.outline.min_distance = vmath.clamp(value, 0, settings.outline.max_distance - 0.1)
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Max distance", settings.outline.max_distance, 0.1, 0.5)
	if changed then
		settings.outline.max_distance = vmath.clamp(value, settings.outline.min_distance + 0.1, 1000)
		uniforms_changed = true
	end

	imgui.separator()
	imgui.text("Grazing prevention:")

	local changed, value = imgui.input_float("Grazing fresnel power", settings.outline.grazing_fresnel_power, 1, 1)
	if changed then
		settings.outline.grazing_fresnel_power = vmath.clamp(value, 1, 16)
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Grazing angle mask power", settings.outline.grazing_angle_mask_power, 1, 1)
	if changed then
		settings.outline.grazing_angle_mask_power = vmath.clamp(value, 1, 16)
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Grazing angle modulation factor", settings.outline.grazing_angle_modulation_factor, 1, 1)
	if changed then
		settings.outline.grazing_angle_modulation_factor = vmath.clamp(value, 0, 100)
		uniforms_changed = true
	end

	if uniforms_changed then
		uniforms.outline.init()
	end

	imgui.spacing()
end
