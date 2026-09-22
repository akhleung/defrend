local settings			= require("defrend.render.settings")
local uniforms			= require("defrend.render.uniforms")
local post_processors	= require("defrend.render.post_processors")

return function (self)
	local changed, checked = imgui.checkbox("Enabled", settings.gaussian_blur.enabled)
	if changed then
		settings.gaussian_blur.enabled = checked
		post_processors.regenerate_active_list()
	end

	local changed, value = imgui.input_int("Downsamples", settings.gaussian_blur.downsamples)
	if changed and value then
		settings.gaussian_blur.downsamples = vmath.clamp(value, 0, 3)
	end

	local changed, value = imgui.input_float("Separation", settings.gaussian_blur.separation, 0.1, 0.5)
	if changed and value then
		settings.gaussian_blur.separation = vmath.clamp(value, 0, 1.5)
		uniforms_changed = true
	end

	if uniforms_changed then
		uniforms.gaussian_blur.init()
        uniforms_changed = false
	end

	imgui.spacing()
end
