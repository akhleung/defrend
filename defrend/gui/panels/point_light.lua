---@diagnostic disable: param-type-mismatch
local settings	= require("defrend.render.settings")
local uniforms	= require("defrend.render.uniforms")
local lights	= require("defrend.render.lights").point_lights

local current_light_id = "please select a light"
local current_light = nil

return function (self)
	local uniforms_changed = false

	local changed, checked = imgui.checkbox("Enabled", settings.point_light.enabled)
	if changed then
		settings.point_light.enabled = checked
	end

	local changed, value = imgui.input_int("Attenuation", settings.point_light.attenuation)
	if changed and value then
		settings.point_light.attenuation = value
		uniforms_changed = true
	end

	if imgui.begin_combo("Light ID", current_light_id) then
		for light in pairs(lights) do
			local light_id = "" .. light.id
			if imgui.selectable(light_id, light == current_light) then
				current_light_id = light_id
				current_light = light
			end
		end
		imgui.end_combo()
	end
	if current_light then
		imgui.separator()
		local changed, value = imgui.input_int("Poisson kernel samples", current_light.poisson_samples)
		if changed and value then
			current_light.poisson_samples = vmath.clamp(value, 1, 16)
			uniforms_changed = true
		end
		local changed, value = imgui.input_float("Poisson scale", current_light.poisson_scale, 0.1, 1.0)
		if changed and value then
			current_light.poisson_scale = vmath.clamp(value, 0, 100)
			uniforms_changed = true
		end
		local changed, value = imgui.input_float("Hash factor", current_light.hash_factor, 1.0, 10.0)
		if changed and value then
			current_light.hash_factor = vmath.clamp(value, 0, 100000)
			uniforms_changed = true
		end
		local changed, value = imgui.input_float("Hash scale", current_light.hash_scale, 0.1, 1.0)
		if changed and value then
			current_light.hash_scale = vmath.clamp(value, 0, 100)
			uniforms_changed = true
		end
		local changed, checked = imgui.checkbox("Soft penumbras", current_light.soft_penumbras)
		if changed then
			current_light.soft_penumbras = checked
			uniforms_changed = true
		end
	end

	if uniforms_changed then
		uniforms.point_light.init()
		if current_light then
			current_light:init()
		end
		uniforms_changed = false
	end

	imgui.spacing()
end
