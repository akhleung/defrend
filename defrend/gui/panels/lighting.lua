local settings = require "defrend.render.settings"
local uniforms = require "defrend.render.uniforms"

local saved_sunlight_color

return function (self)
	local uniforms_changed = false

	-- LIGHT TOGGLES
	local changed, checked = imgui.checkbox("Sunlight enabled", settings.light.sunlight_enabled)
	if changed then
		if checked then
			settings.light.sunlight_enabled = true
			settings.light.directional_color = saved_sunlight_color
		else
			settings.light.sunlight_enabled = false
			saved_sunlight_color = settings.light.directional_color
			settings.light.directional_color = vmath.vector4()
		end
		uniforms_changed = true
	end

	local changed, checked = imgui.checkbox("Point lights enabled", settings.light.point_lights_enabled)
	if changed then
		settings.light.point_lights_enabled = checked
	end

	local changed, checked = imgui.checkbox("Spot lights enabled", settings.light.spot_lights_enabled)
	if changed then
		settings.light.spot_lights_enabled = checked
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

	-- POINT LIGHT ATTENUATION
	local changed, value = imgui.input_int("Point light attenuation", settings.light.point_light_attenuation)
	if changed then
		settings.light.point_light_attenuation = value
		uniforms_changed = true
	end

	-- SPOT LIGHT ATTENUATION
	local changed, value = imgui.input_int("Spot light range attenuation", settings.light.spot_light_range_attenuation)
	if changed then
		settings.light.spot_light_range_attenuation = value
		uniforms_changed = true
	end

	local changed, value = imgui.input_int("Spot light spread attenuation", settings.light.spot_light_spread_attenuation)
	if changed then
		settings.light.spot_light_spread_attenuation = value
		uniforms_changed = true
	end

	-- AMBIENT LIGHT COLOR
	local new_ambient_color = vmath.vector4(settings.light.ambient_color)
	imgui.color_edit4("Ambient color", new_ambient_color, imgui.COLOREDITFLAGS_ALPHABAR)
	if new_ambient_color ~= settings.light.ambient_color then
		settings.light.ambient_color = new_ambient_color
		uniforms_changed = true
	end

	-- FOG SETTINGS
	local new_fog_color = vmath.vector4(settings.light.fog_color)
	imgui.color_edit4("Fog color", new_fog_color, imgui.COLOREDITFLAGS_ALPHABAR)
	if new_fog_color ~= settings.light.fog_color then
		settings.light.fog_color = new_fog_color
		uniforms_changed = true
	end

	local changed, value = imgui.input_int("Fog start distance", settings.light.fog_near)
	if changed then
		settings.light.fog_near = value
		uniforms_changed = true
	end

	local changed, value = imgui.input_int("Fog full distance", settings.light.fog_far)
	if changed then
		settings.light.fog_far = value
		uniforms_changed = true
	end

	if uniforms_changed then
		uniforms.light.init()
	end

	imgui.spacing()
end
