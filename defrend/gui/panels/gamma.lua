local settings			= require("defrend.render.settings")
local uniforms			= require("defrend.render.uniforms")
local post_processors	= require("defrend.render.post_processors")

return function (self)
	local uniforms_changed = false

	local changed, checked = imgui.checkbox("Enabled", settings.gamma.enabled)
	if changed then
		settings.gamma.enabled = checked
		post_processors.regenerate_active_list()
	end

	local changed, value = imgui.input_float("Gamma", settings.gamma.gamma, 0.1, 0.2)
	if changed and value then
		settings.gamma.gamma = vmath.clamp(value, 1, 10)
		uniforms_changed = true
	end

	if uniforms_changed then
		uniforms.gamma.init()
        uniforms_changed = false
	end

	imgui.spacing()
end
