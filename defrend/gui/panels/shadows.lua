local SCRIPT_URL = "/defrend/lighting#shadow"
local p_props = { "cascade.x", "cascade.y", "cascade.z", "cascade.w" }
local t_props = { "partition_1_tint", "partition_2_tint", "partition_3_tint", "partition_4_tint" }
local b_props = { "biases.x", "biases.y", "biases.z", "biases.w" }
local visualize = false
local saved_tints = {}
local visualization_tints = {
	vmath.vector4(1, 0, 0, 0),
	vmath.vector4(0, 1, 0, 0),
	vmath.vector4(0, 0, 1, 0),
	vmath.vector4(1, 1, 0, 0),
}
local atlas_resolutions = { 512, 1024, 2048, 4096, 8192 }

return function (self)
	local properties_changed = false

	local changed, checked = imgui.checkbox("Enabled", go.get(SCRIPT_URL, "enabled"))
	if changed then
		go.set(SCRIPT_URL, "enabled", checked)
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
	imgui.text("Partition tints:")
	for i = 1, 4 do
		imgui.push_id(("Partition %d tint"):format(i))
		local old_partition_tint = go.get(SCRIPT_URL, t_props[i])
		local new_partition_tint = vmath.vector4(old_partition_tint) ---@diagnostic disable-line: param-type-mismatch
		imgui.color_edit4(("Partition %d"):format(i), new_partition_tint, imgui.COLOREDITFLAGS_NOALPHA)
		if new_partition_tint ~= old_partition_tint then
			go.set(SCRIPT_URL, t_props[i], new_partition_tint)
			properties_changed = true
		end
		imgui.pop_id()
	end
	local changed, checked = imgui.checkbox("Visualize partitions", visualize)
	if changed and checked then
		visualize = true
		for i = 1, 4 do
			saved_tints[i] = go.get(SCRIPT_URL, t_props[i])
			go.set(SCRIPT_URL, t_props[i], visualization_tints[i])
		end
		properties_changed = true
	elseif changed and not checked then
		visualize = false
		for i = 1, 4 do
			go.set(SCRIPT_URL, t_props[i], saved_tints[i])
		end
		properties_changed = true
	end
	imgui.separator()

	local changed, value = imgui.input_float("Cascade transition range", go.get(SCRIPT_URL, "cascade_transition_range"), 0.1, 1.0)
	if changed then
		go.set(SCRIPT_URL, "cascade_transition_range", vmath.clamp(value, 0, 50))
		properties_changed = true
	end

	local current_res = go.get(SCRIPT_URL, "atlas_resolution")
	local new_res = current_res
	local res_changed = false
	if imgui.begin_combo("Atlas resolution", current_res) then
		for i = 1, #atlas_resolutions do
			local res_option_i = atlas_resolutions[i]
			if imgui.selectable(res_option_i, current_res == res_option_i) then
				new_res = res_option_i
			end
			if new_res ~= current_res and not res_changed then
				go.set(SCRIPT_URL, "atlas_resolution", vmath.clamp(new_res, atlas_resolutions[1], atlas_resolutions[#atlas_resolutions])) ---@diagnostic disable-line: param-type-mismatch
				properties_changed = true
			end
		end
		imgui.end_combo()
	end

	local changed, value = imgui.input_float("Light frustum Z padding", go.get(SCRIPT_URL, "light_frustum_z_padding"), 0.05, 0.1)
	if changed then
		go.set(SCRIPT_URL, "light_frustum_z_padding", vmath.clamp(value, 0, 20))
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
	end

	imgui.spacing()
end
