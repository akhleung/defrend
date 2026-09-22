local settings			= require("defrend.render.settings")
local uniforms			= require("defrend.render.uniforms")
local post_processors	= require("defrend.render.post_processors")

return function (self)
	local uniforms_changed = false

	local changed, checked = imgui.checkbox("Enabled", settings.glow.enabled)
	if changed then
		settings.glow.enabled = checked
		post_processors.regenerate_active_list()
	end

	local changed, value = imgui.input_int("Iterations", settings.glow.iterations)
	if changed and value then
		settings.glow.iterations = vmath.clamp(value,1, 3)
	end

	local changed, value = imgui.input_float("Separation", settings.glow.separation, 0.1, 0.5)
	if changed and value then
		settings.glow.separation = vmath.clamp(value, 0, 5)
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Bloom", settings.glow.bloom, 0.1, 0.5)
	if changed and value then
		settings.glow.bloom = vmath.clamp(value, 1.0, 5.0)
		uniforms_changed = true
	end

	if uniforms_changed then
		uniforms.glow.init()
        uniforms_changed = false
	end

	imgui.spacing()
end
