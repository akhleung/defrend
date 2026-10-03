---@diagnostic disable: param-type-mismatch
local settings	= require("defrend.render.settings")
local uniforms	= require("defrend.render.uniforms")
local shadows	= require("defrend.render.shadows.point_light")

local MSG_REFRESH						= hash("refresh")
local MSG_UNIFORMS						= hash("uniforms")
local MSG_RESIZE_POINT_LIGHT_SHADOW_MAP	= hash("resize_point_light_shadow_map")

local map_resolutions = { 128, 192, 256, 384, 512, 768, 1024, 1536, 2048, 3072, 4096 }
local lights = {}

return function (self)
	local uniforms_changed = false
	local shadowmap_changed = false

	local changed, checked = imgui.checkbox("Enabled", settings.point_light.enabled)
	if changed then
		settings.point_light.enabled = checked
	end

	local changed, value = imgui.input_int("Attenuation", settings.point_light.attenuation)
	if changed and value then
		settings.point_light.attenuation = value
		uniforms_changed = true
	end

	local changed, value = imgui.input_int("Shadow caster count", settings.point_light.shadow_caster_count)
	if changed and value then
		settings.point_light.shadow_caster_count = value
		shadowmap_changed = true
	end

	local current_res = settings.point_light.shadow_map_resolution
	local new_res = current_res
	local res_changed = false
	if imgui.begin_combo("Shadow map resolution", current_res) then
		for i = 1, #map_resolutions do
			local res_option_i = map_resolutions[i]
			if imgui.selectable(res_option_i, current_res == res_option_i) then
				new_res = res_option_i
			end
			if new_res ~= current_res and not res_changed then
				settings.point_light.shadow_map_resolution = vmath.clamp(new_res, map_resolutions[1], map_resolutions[#map_resolutions]) ---@diagnostic disable-line: param-type-mismatch
				shadowmap_changed = true
			end
		end
		imgui.end_combo()
	end

	local changed, value = imgui.input_float("Shadow bias near", settings.point_light.shadow_bias_near, 0.05, 0.1)
	if changed and value then
		settings.point_light.shadow_bias_near = value
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Shadow bias far", settings.point_light.shadow_bias_far, 0.05, 0.1)
	if changed and value then
		settings.point_light.shadow_bias_far = value
		uniforms_changed = true
	end

	local changed, value = imgui.input_int("PCF samples", settings.point_light.pcf_samples)
	if changed and value then
		settings.point_light.pcf_samples = vmath.clamp(value, 0, 8)
		uniforms_changed = true
	end

	local changed, value = imgui.input_int("Poisson disc samples", settings.point_light.poisson_samples)
	if changed and value then
		settings.point_light.poisson_samples = vmath.clamp(value, 0, 16)
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Poisson scale", settings.point_light.poisson_scale, 0.1, 1.0)
	if changed and value then
		settings.point_light.poisson_scale = vmath.clamp(value, 0, 1000)
		uniforms_changed = true
	end

	local changed, checked = imgui.checkbox("Soft penumbras", settings.point_light.soft_penumbras)
	if changed then
		settings.point_light.soft_penumbras = checked
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Hash factor", settings.point_light.hash_factor, 1.0, 10.0)
	if changed and value then
		settings.point_light.hash_factor = vmath.clamp(value, 0.000001, 1000000)
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Hash scale", settings.point_light.hash_scale, 0.1, 1.0)
	if changed and value then
		settings.point_light.hash_scale = vmath.clamp(value, 0, 1000)
		uniforms_changed = true
	end

	if uniforms_changed then
		uniforms.point_light.init()
		shadows.for_each(function (url)
			msg.post(url, MSG_UNIFORMS)
		end)
		uniforms_changed = false
	end

	if shadowmap_changed then
		msg.post("@render:", MSG_RESIZE_POINT_LIGHT_SHADOW_MAP)
		shadows.init()
		for _, url in ipairs(lights) do
			msg.post(url, MSG_REFRESH)
		end
	end

	imgui.spacing()
end
