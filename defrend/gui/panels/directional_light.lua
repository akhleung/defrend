local settings	= require("defrend.render.settings")
local lights	= require("defrend.render.lights").directional_lights

local p_props = { "x", "y", "z", "w" }
local b_props = { "x", "y", "z", "w" }
local t_props = { "partition_1_tint", "partition_2_tint", "partition_3_tint", "partition_4_tint" }
local visualize = false
local saved_tints = {}
local visualization_tints = {
	vmath.vector4(1, 0, 0, 0),
	vmath.vector4(0, 1, 0, 0),
	vmath.vector4(0, 0, 1, 0),
	vmath.vector4(1, 1, 0, 0),
}
local current_light_id = "please select a light"
local current_light = nil

return function (self)
	local uniforms_changed = false

	-- LIGHT TOGGLE
	local changed, checked = imgui.checkbox("Enabled", settings.directional_light.enabled)
	if changed then
		settings.directional_light.enabled = checked
		-- if checked then
		-- 	settings.light.directional_color = settings.light.saved_color
		-- else
		-- 	settings.light.saved_color = settings.light.directional_color
		-- 	settings.light.directional_color = vmath.vector4()
		-- end
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
		local color = vmath.vector4(current_light.color)
		imgui.color_edit4("Color", color, imgui.COLOREDITFLAGS_ALPHABAR)
		if color ~= current_light.color then
			current_light.color = color
			uniforms_changed = true
		end
		imgui.separator()
		imgui.text("Partition sizes (normalized):")
		for i = 1, 4 do
			imgui.push_id(("Partition %d size"):format(i))
			local changed, value = imgui.input_float(("Partition %d"):format(i), current_light.cascade[p_props[i]], 0.01, 0.05)
			imgui.pop_id()
			if changed and value then
				current_light.cascade[p_props[i]] = vmath.clamp(value, 0, 1)
				uniforms_changed = true
			end
		end
		imgui.separator()
		imgui.text("Partition biases:")
		for i = 1, 4 do
			imgui.push_id(("Partition %d bias"):format(i))
			local changed, value = imgui.input_float(("Partition %d"):format(i), current_light.cascade[b_props[i]], 0.01, 0.05)
			imgui.pop_id()
			if changed and value then
				current_light.cascade[b_props[i]] = vmath.clamp(value, 0, 10)
				uniforms_changed = true
			end
		end
		imgui.separator()
		imgui.text("Partition tints:")
		for i = 1, 4 do
			imgui.push_id(("Partition %d tint"):format(i))
			local old_partition_tint = current_light[t_props[i]]
			local new_partition_tint = vmath.vector4(old_partition_tint)
			imgui.color_edit4(("Partition %d"):format(i), new_partition_tint, imgui.COLOREDITFLAGS_NOALPHA)
			if new_partition_tint ~= old_partition_tint then
				current_light[t_props[i]] = new_partition_tint
				uniforms_changed = true
			end
			imgui.pop_id()
		end
		local changed, checked = imgui.checkbox("Visualize partitions", visualize)
		if changed and checked then
			visualize = true
			for i = 1, 4 do
				saved_tints[i] = current_light[t_props[i]]
				current_light[t_props[i]] = visualization_tints[i]
			end
			uniforms_changed = true
		elseif changed and not checked then
			visualize = false
			for i = 1, 4 do
				current_light[t_props[i]] = saved_tints[i]
			end
			uniforms_changed = true
		end
		imgui.separator()

		local changed, value = imgui.input_float("Cascade transition range", current_light.cascade_transition_range, 0.1, 1.0)
		if changed and value then
			current_light.cascade_transition_range = vmath.clamp(value, 0, 50)
			uniforms_changed = true
		end
		local changed, value = imgui.input_float("Light frustum Z padding", current_light.light_frustum_z_padding, 0.05, 0.1)
		if changed and value then
			current_light.light_frustum_z_padding = vmath.clamp(value, 0, 20)
			uniforms_changed = true
		end
		local changed, value = imgui.input_int("PCF samples", current_light.pcf_samples)
		if changed and value then
			current_light.pcf_samples = vmath.clamp(value, 0, 8)
			uniforms_changed = true
		end
		local changed, value = imgui.input_int("Poisson samples", current_light.poisson_samples)
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
		if current_light then
			current_light:init()
		end
        uniforms_changed = false
	end

	imgui.spacing()
end
