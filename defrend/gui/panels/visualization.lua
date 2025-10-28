local settings = require "defrend.render.settings"
local visualize = settings.visualize

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

	if imgui.radio_button("Light volume diffuse reflectance", visualize.option == "reflectance_diffuse") then
		visualize.option = "reflectance_diffuse"
	end

	if imgui.radio_button("Light volume specular reflectance", visualize.option == "reflectance_specular") then
		visualize.option = "reflectance_specular"
	end

	if imgui.radio_button("Shadow atlas", visualize.option == "shadow_atlas") then
		visualize.option = "shadow_atlas"
	end

	if imgui.radio_button("SSAO", visualize.option == "ssao") then
		visualize.option = "ssao"
	end

	imgui.spacing()
end
