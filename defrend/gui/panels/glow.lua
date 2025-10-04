local settings = require "defrend.render.settings"
local uniforms = require "defrend.render.uniforms"

return function (self)
	local uniforms_changed = false

	local changed, checked = imgui.checkbox("Enabled", settings.glow.enabled)
	if changed then
		settings.glow.enabled = checked
	end

	local changed, checked = imgui.checkbox("Downsample", settings.glow.downsample)
	if changed then
		settings.glow.downsample = checked
		uniforms_changed = true
	end

	if uniforms_changed then
		uniforms.glow.init()
	end

	imgui.spacing()
end
