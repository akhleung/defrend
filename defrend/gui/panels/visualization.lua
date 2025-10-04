local settings = require "defrend.render.settings"
local visualize = settings.visualize

return function (self)

	if imgui.radio_button("Disabled", visualize.option == nil) then
		visualize.option = nil
	end

	if imgui.radio_button("G-buffer diffuse", visualize.option == "g_diffuse") then
		visualize.option = "g_diffuse"
	end

	if imgui.radio_button("G-buffer normals", visualize.option == "g_normals") then
		visualize.option = "g_normals"
	end

	if imgui.radio_button("G-buffer specular & glow", visualize.option == "g_spec_glow") then
		visualize.option = "g_spec_glow"
	end

	if imgui.radio_button("Light volume diffuse reflectance", visualize.option == "l_diffuse") then
		visualize.option = "l_diffuse"
	end

	if imgui.radio_button("Light volume specular reflectance", visualize.option == "l_specular") then
		visualize.option = "l_specular"
	end

	if imgui.radio_button("Shadow atlas", visualize.option == "shadow_atlas") then
		visualize.option = "shadow_atlas"
	end

	if imgui.radio_button("SSAO", visualize.option == "ssao") then
		visualize.option = "ssao"
	end

	imgui.spacing()
end
