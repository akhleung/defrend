local settings			= require("defrend.render.settings")
local uniforms			= require("defrend.render.uniforms")
local post_processors	= require("defrend.render.post_processors")

return function (self)
	local uniforms_changed = false

	local changed, checked = imgui.checkbox("Enabled", settings.dof.enabled)
	if changed then
		settings.dof.enabled = checked
		post_processors.regenerate_active_list()
	end

	local changed, value = imgui.input_float("Focal depth", settings.dof.focal_depth, 1.0, 5.0)
	if changed and value then
		if value < 0 then
			value = 0
		end
		settings.dof.focal_depth = value
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Blur start", settings.dof.blur_start, 1.0, 5.0)
	if changed and value then
		settings.dof.blur_start = vmath.clamp(value, 0, settings.dof.blur_full - 1)
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Blur full", settings.dof.blur_full, 1.0, 5.0)
	if changed and value then
		settings.dof.blur_full = vmath.clamp(value, settings.dof.blur_start + 1, 2000000000)
		uniforms_changed = true
	end

	local changed, value = imgui.input_int("Blur samples", settings.dof.blur_samples)
	if changed and value then
		settings.dof.blur_samples = vmath.clamp(value, 1, 64)
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Blur radius", settings.dof.blur_radius, 0.1, 0.5)
	if changed and value then
		settings.dof.blur_radius = vmath.clamp(value, 0.1, 16)
		uniforms_changed = true
	end

	local changed, value = imgui.input_int("Downsampling passes", settings.dof.downsamples)
	if changed and value then
		settings.dof.downsamples = vmath.clamp(value, 0, 3)
	end

	local changed, value = imgui.input_float("Focused CoC threshold", settings.dof.coc_threshold, 0.001, 0.01)
	if changed and value then
		settings.dof.coc_threshold = vmath.clamp(value, 0, 0.5)
		uniforms_changed = true
	end

	imgui.separator()
	imgui.text("Debugging visualizations")

	if imgui.radio_button("Disabled", settings.dof.coc_visualization == 0) then
		settings.dof.coc_visualization = 0
		uniforms_changed = true
	end

	if imgui.radio_button("Original CoCs", settings.dof.coc_visualization == 1) then
		settings.dof.coc_visualization = 1
		uniforms_changed = true
	end

	if imgui.radio_button("Dilated CoCs", settings.dof.coc_visualization == 2) then
		settings.dof.coc_visualization = 2
		uniforms_changed = true
	end

	if imgui.radio_button("Corrected CoCs", settings.dof.coc_visualization == 3) then
		settings.dof.coc_visualization = 3
		uniforms_changed = true
	end

	if uniforms_changed then
		uniforms.dof_coc.init()
        uniforms_changed = false
	end

	imgui.spacing()
end
