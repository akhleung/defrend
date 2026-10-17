local settings	= require("defrend.render.settings")
local uniforms	= require("defrend.render.uniforms")
local shadows	= require("defrend.gui.panels.directional_shadows")

return function (self)
	local uniforms_changed = false

	-- LIGHT TOGGLE
	local changed, checked = imgui.checkbox("Sunlight enabled", settings.light.sunlight_enabled)
	if changed then
		settings.light.sunlight_enabled = checked
		if checked then
			settings.light.directional_color = settings.light.saved_color
		else
			settings.light.saved_color = settings.light.directional_color
			settings.light.directional_color = vmath.vector4()
		end
		uniforms_changed = true
	end

	-- SUNLIGHT COLOR
	if settings.light.sunlight_enabled then
		local new_sunlight_color = vmath.vector4(settings.light.directional_color)
		imgui.color_edit4("Sunlight color", new_sunlight_color, imgui.COLOREDITFLAGS_ALPHABAR)
		if new_sunlight_color ~= settings.light.directional_color then
			settings.light.directional_color = new_sunlight_color
			uniforms_changed = true
		end
	else
		imgui.color_edit4("Sunlight color", vmath.vector4(), imgui.COLOREDITFLAGS_ALPHABAR)
	end

	if uniforms_changed then
		uniforms.light.init()
        uniforms_changed = false
	end

	imgui.spacing()
	shadows(self)
end
