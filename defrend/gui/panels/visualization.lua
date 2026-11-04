local settings			= require("defrend.render.settings")
local lights			= require("defrend.render.lights")
local visualizations	= require("defrend.render.visualizations")

local visualize	= settings.visualize
local directional_light
local spot_light
local prev_light

---@param id string
---@param lights table<Directional_Light, boolean> | table<Point_Light, boolean> | table<Spot_Light, boolean>
---@param current_light Directional_Light | Point_Light | Spot_Light
---@return Directional_Light | Point_Light | Spot_Light
local function lights_menu(id, lights, current_light)
	if imgui.begin_combo(id, "" .. current_light.id) then
		for light in pairs(lights) do
			if imgui.selectable("" .. light.id, light == current_light) then
				current_light = light
			end
		end
		imgui.end_combo()
	end
    return current_light
end

return function (self)

	if imgui.radio_button("Disabled", visualize.option == nil) then
		visualize.option = nil
	end

	if imgui.radio_button("G-buffer albedo", visualize.option == "g_albedo") then
		visualize.option = "g_albedo"
	end

	if imgui.radio_button("G-buffer normals", visualize.option == "g_normals") then
		visualize.option = "g_normals"
	end

	if imgui.radio_button("G-buffer specular", visualize.option == "g_specular") then
		visualize.option = "g_specular"
	end

	if imgui.radio_button("G-buffer emissive", visualize.option == "g_emissive") then
		visualize.option = "g_emissive"
	end

	if imgui.radio_button("G-buffer depth", visualize.option == "g_depth") then
		visualize.option = "g_depth"
	end

	if imgui.radio_button("Light buffer (diffuse)", visualize.option == "reflectance_diffuse") then
		visualize.option = "reflectance_diffuse"
	end

	if imgui.radio_button("Light buffer (specular)", visualize.option == "reflectance_specular") then
		visualize.option = "reflectance_specular"
	end

	if imgui.radio_button("SSAO", visualize.option == "ssao") then
		visualize.option = "ssao"
	end

	local first_directional_light = next(lights.directional_lights)
	if first_directional_light and not directional_light then
		directional_light = first_directional_light
	end
	if imgui.radio_button("Shadow atlas (directional)", visualize.option == "directional_light_shadow") and first_directional_light then
		visualize.option = "directional_light_shadow"
	end
	if not first_directional_light then
		imgui.text("No directional lights")
	else
		directional_light = lights_menu("Directional light ID", lights.directional_lights, directional_light)
	end
	if visualize.option == "directional_light_shadow" and prev_light ~= directional_light then
		visualizations.set_shadow_map(directional_light.render_target)
		prev_light = directional_light
	end

	local first_spot_light = next(lights.spot_lights)
	if first_spot_light and not spot_light then
		spot_light = first_spot_light
	end
	if imgui.radio_button("Shadow map (spot light)", visualize.option == "spot_light_shadow") and first_spot_light then
		visualize.option = "spot_light_shadow"
	end
	if not first_spot_light then
		imgui.text("No spot lights")
	else
		spot_light = lights_menu("Spot light ID", lights.spot_lights, spot_light)
	end
	if visualize.option == "spot_light_shadow" and prev_light ~= spot_light then
		visualizations.set_shadow_map(spot_light.render_target)
		prev_light = spot_light
	end

	imgui.spacing()
end
