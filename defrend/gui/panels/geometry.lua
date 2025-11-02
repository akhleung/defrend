local settings = require "defrend.render.settings"

return function (self)

	local changed, checked = imgui.checkbox("Models", settings.geometry.models_enabled)
	if changed then
		settings.geometry.models_enabled = checked
	end

	local changed, checked = imgui.checkbox("Sprites", settings.geometry.sprites_enabled)
	if changed then
		settings.geometry.sprites_enabled = checked
	end

	local changed, checked = imgui.checkbox("Billboards", settings.geometry.billboards_enabled)
	if changed then
		settings.geometry.billboards_enabled = checked
	end

	local changed, checked = imgui.checkbox("Particles", settings.geometry.particles_enabled)
	if changed then
		settings.geometry.particles_enabled = checked
	end

	local changed, checked = imgui.checkbox("Decals", settings.geometry.decals_enabled)
	if changed then
		settings.geometry.decals_enabled = checked
	end

	local changed, checked = imgui.checkbox("Skybox", settings.geometry.skybox_enabled)
	if changed then
		settings.geometry.skybox_enabled = checked
	end

	imgui.spacing()
end
