local settings			= require("defrend.render.settings")
local uniforms			= require("defrend.render.uniforms")
local post_processors	= require("defrend.render.post_processors")

return function (self)
	local uniforms_changed = false

	local changed, checked = imgui.checkbox("Enabled", settings.fxaa.enabled)
	if changed then
		settings.fxaa.enabled = checked
		post_processors.regenerate_active_list()
	end

	local changed, value = imgui.input_int("Iterations", settings.fxaa.iterations)
	if changed and value then
		settings.fxaa.iterations = vmath.clamp(value, 3, 32)
		uniforms_changed = true
	end

	if uniforms_changed then
		uniforms.fxaa.init()
        uniforms_changed = false
	end

	imgui.spacing()
end
