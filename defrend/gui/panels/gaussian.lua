local settings = require "defrend.render.settings"

return function (self)
	local changed, checked = imgui.checkbox("Enabled", settings.gaussian_blur.enabled)
	if changed then
		settings.gaussian_blur.enabled = checked
	end
end
