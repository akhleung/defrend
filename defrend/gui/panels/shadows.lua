local SCRIPT_URL = "/defrend/lighting#shadow"
local p_props = { "cascade.x", "cascade.y", "cascade.z", "cascade.w" }
local b_props = { "biases.x", "biases.y", "biases.z", "biases.w" }

return function (self)
	local properties_changed = false

	local changed, checked = imgui.checkbox("Enabled", go.get(SCRIPT_URL, "enabled"))
	if changed then
		go.set(SCRIPT_URL, "enabled", checked)
		properties_changed = true
	end

	local changed, checked = imgui.checkbox("Stable shadows", go.get(SCRIPT_URL, "stable_shadows"))
	if changed then
		go.set(SCRIPT_URL, "stable_shadows", checked)
		properties_changed = true
	end

	imgui.separator()
	imgui.text("Partition sizes (normalized):")
	for i = 1, 4 do
		imgui.push_id(("Partition %d size"):format(i))
		local changed, value = imgui.input_float(("Partition %d"):format(i), go.get(SCRIPT_URL, p_props[i]), 0.01, 0.05)
		imgui.pop_id()
		if changed then
			go.set(SCRIPT_URL, p_props[i], vmath.clamp(value, 0, 1))
			properties_changed = true
		end
	end
	imgui.separator()
	imgui.text("Partition biases:")
	for i = 1, 4 do
		imgui.push_id(("Partition %d bias"):format(i))
		local changed, value = imgui.input_float(("Partition %d"):format(i), go.get(SCRIPT_URL, b_props[i]), 0.01, 0.05)
		imgui.pop_id()
		if changed then
			go.set(SCRIPT_URL, b_props[i], vmath.clamp(value, 0, 10))
			properties_changed = true
		end
	end
	imgui.separator()

	local changed, value = imgui.input_float("Cascade transition range", go.get(SCRIPT_URL, "cascade_transition_range"), 0.1, 1.0)
	if changed then
		go.set(SCRIPT_URL, "cascade_transition_range", vmath.clamp(value, 0, 50))
		properties_changed = true
	end
	local changed, value = imgui.input_int("Atlas resolution", go.get(SCRIPT_URL, "atlas_resolution"))
	if changed then
		go.set(SCRIPT_URL, "atlas_resolution", vmath.clamp(value, 1, 8192))
		properties_changed = true
	end
	local changed, value = imgui.input_float("Light frustum Z padding", go.get(SCRIPT_URL, "light_frustum_z_padding"), 0.05, 0.1)
	if changed then
		go.set(SCRIPT_URL, "light_frustum_z_padding", vmath.clamp(value, 0, 5))
		properties_changed = true
	end
	local changed, value = imgui.input_int("PCF samples", go.get(SCRIPT_URL, "pcf_samples"))
	if changed then
		go.set(SCRIPT_URL, "pcf_samples", vmath.clamp(value, 0, 8))
		properties_changed = true
	end
	local changed, value = imgui.input_int("Poisson disc samples", go.get(SCRIPT_URL, "poisson_disc_samples"))
	if changed then
		go.set(SCRIPT_URL, "poisson_disc_samples", vmath.clamp(value, 1, 16))
		properties_changed = true
	end
	local changed, value = imgui.input_float("Poisson scale", go.get(SCRIPT_URL, "poisson_scale"), 1.0, 10.0)
	if changed then
		go.set(SCRIPT_URL, "poisson_scale", vmath.clamp(value, 0, 10000))
		properties_changed = true
	end
	local changed, checked = imgui.checkbox("Soft penumbras", go.get(SCRIPT_URL, "soft_penumbras"))
	if changed then
		go.set(SCRIPT_URL, "soft_penumbras", checked)
		properties_changed = true
	end

	if properties_changed then
		msg.post(SCRIPT_URL, "refresh")
        properties_changed = false
	end

	imgui.spacing()
end
