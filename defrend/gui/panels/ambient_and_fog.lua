local settings = require("defrend.render.settings")
local uniforms = require("defrend.render.uniforms")

return function (self)
	local uniforms_changed = false

	-- AMBIENT LIGHT COLOR
	local new_ambient_color = vmath.vector4(settings.ambient_and_fog.ambient_color)
	imgui.color_edit4("Ambient color", new_ambient_color, imgui.COLOREDITFLAGS_ALPHABAR)
	if new_ambient_color ~= settings.ambient_and_fog.ambient_color then
		settings.ambient_and_fog.ambient_color = new_ambient_color
		uniforms_changed = true
	end

	-- FOG SETTINGS
	local new_fog_color = vmath.vector4(settings.ambient_and_fog.fog_color)
	imgui.color_edit4("Fog color", new_fog_color, imgui.COLOREDITFLAGS_ALPHABAR)
	if new_fog_color ~= settings.ambient_and_fog.fog_color then
		settings.ambient_and_fog.fog_color = new_fog_color
		uniforms_changed = true
	end

	local changed, value = imgui.input_int("Fog start distance", settings.ambient_and_fog.fog_near)
	if changed and value then
		settings.ambient_and_fog.fog_near = value
		uniforms_changed = true
	end

	local changed, value = imgui.input_int("Fog full distance", settings.ambient_and_fog.fog_far)
	if changed and value then
		settings.ambient_and_fog.fog_far = value
		uniforms_changed = true
	end

	if uniforms_changed then
		uniforms.ambient_and_fog.init()
        uniforms_changed = false
	end

	imgui.spacing()
end
