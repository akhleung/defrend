local settings	= require "defrend.render.settings"
local uniforms	= require "defrend.render.uniforms"
local queue		= require("defrend.scripts.configurators.queue")

return function (self)
	local uniforms_changed = false

	local changed, checked = imgui.checkbox("Spot lights enabled", settings.spot_light.enabled)
	if changed then
		settings.spot_light.enabled = checked
	end

   	-- ATTENUATION
	local changed, value = imgui.input_int("Spot light range attenuation", settings.spot_light.range_attenuation)
	if changed and value then
		settings.spot_light.range_attenuation = value
		uniforms_changed = true
	end

	local changed, value = imgui.input_int("Spot light spread attenuation", settings.spot_light.spread_attenuation)
	if changed and value then
		settings.spot_light.range_attenuation = value
		uniforms_changed = true
	end

	-- SHADOW SETTINGS
	local changed, value = imgui.input_float("Shadow bias near", settings.spot_light.shadow_bias_near, 0.05, 0.1)
	if changed and value then
		settings.spot_light.shadow_bias_near = value
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Shadow bias far", settings.spot_light.shadow_bias_far, 0.05, 0.1)
	if changed and value then
		settings.spot_light.shadow_bias_far = value
		uniforms_changed = true
	end

	local changed, value = imgui.input_int("PCF samples", settings.spot_light.pcf_samples)
	if changed and value then
		settings.spot_light.pcf_samples = vmath.clamp(value, 0, 8)
		uniforms_changed = true
	end

	local changed, value = imgui.input_int("Poisson disc samples", settings.spot_light.poisson_samples)
	if changed and value then
		settings.spot_light.poisson_samples = vmath.clamp(value, 0, 16)
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Poisson scale", settings.spot_light.poisson_scale, 0.1, 1.0)
	if changed and value then
		settings.spot_light.poisson_scale = vmath.clamp(value, 0, 1000)
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Hash factor", settings.spot_light.hash_factor, 1.0, 10.0)
	if changed and value then
		settings.spot_light.hash_factor = vmath.clamp(value, 0.000001, 1000000)
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Hash scale", settings.spot_light.hash_scale, 0.1, 1.0)
	if changed and value then
		settings.spot_light.hash_scale = vmath.clamp(value, 0, 1000)
		uniforms_changed = true
	end

	local changed, checked = imgui.checkbox("Soft penumbras", settings.spot_light.soft_penumbras)
	if changed then
		settings.spot_light.soft_penumbras = checked
		uniforms_changed = true
	end

	if uniforms_changed then
		uniforms.spot_light.init()
		queue.init_pending_spot_lights()
		uniforms_changed = false
	end

	imgui.spacing()
end