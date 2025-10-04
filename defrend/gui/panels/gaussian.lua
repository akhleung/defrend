local settings = require "defrend.render.settings"

return function (self)
	local changed, checked = imgui.checkbox("Enabled", settings.gaussian_blur.enabled)
	if changed then
		settings.gaussian_blur.enabled = checked
	end

	local changed, checked = imgui.checkbox("Downsample", settings.gaussian_blur.downsample)
	if changed then
		settings.gaussian_blur.downsample = checked
	end

	imgui.spacing()
end
