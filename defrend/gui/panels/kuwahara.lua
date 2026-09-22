local settings			= require("defrend.render.settings")
local uniforms			= require("defrend.render.uniforms")
local post_processors	= require("defrend.render.post_processors")

return function (self)
	local uniforms_changed = false

	local changed, checked = imgui.checkbox("Enabled", settings.kuwahara_blur.enabled)
	if changed then
		settings.kuwahara_blur.enabled = checked
		post_processors.regenerate_active_list()
	end

	local changed, value = imgui.input_int("Iterations", settings.kuwahara_blur.samples)
	if changed and value then
		settings.kuwahara_blur.samples = vmath.clamp(value, 0, 16)
		uniforms_changed = true
	end

	if uniforms_changed then
		uniforms.kuwahara_blur.init()
        uniforms_changed = false
	end

	imgui.spacing()
end
