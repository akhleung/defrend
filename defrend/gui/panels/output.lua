local settings	= require("defrend.render.settings").output
local output_pp = require("defrend.render.post_processors.output")

local MODES = {
	"Linear",
	"Reinhard",
	"Filmic",
	"Aces",
	"AGX",
}

return function (self)
	local uniforms_changed = false

	local changed, checked = imgui.checkbox("Enabled", settings.enabled)
	if changed then
		settings.enabled = checked
	end

	if imgui.begin_combo("Tonemapping mode", MODES[settings.mode]) then
		for i, mode in ipairs(MODES) do
			if imgui.selectable(mode, settings.mode == i) then
				settings.mode = i
				uniforms_changed = true
			end
		end
		imgui.end_combo()
	end

	local changed, value = imgui.input_float("Exposure", settings.exposure, 0.05, 0.1)
	if changed and value then
		settings.exposure = vmath.clamp(value, 0, 100)
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("White point", settings.white, 0.05, 0.1)
	if changed and value then
		settings.white = vmath.clamp(value, 0, 100)
		uniforms_changed = true
	end

	local changed, value = imgui.input_float("Brightness", settings.brightness, 0.05, 0.1)
	if changed and value then
		settings.brightness = vmath.clamp(value, 0, 100)
		uniforms_changed = true
	end

    local changed, value = imgui.input_float("Contrast", settings.contrast, 0.05, 0.1)
    if changed and value then
        settings.contrast = vmath.clamp(value, 0, 100)
        uniforms_changed = true
    end

    local changed, value = imgui.input_float("Saturation", settings.saturation, 0.05, 0.1)
    if changed and value then
        settings.saturation = vmath.clamp(value, 0, 100)
        uniforms_changed = true
    end

	local changed, checked = imgui.checkbox("Gamma correction", settings.gamma)
	if changed then
		settings.gamma = checked
        uniforms_changed = true
	end

	local changed, checked = imgui.checkbox("Debanding", settings.debanding)
	if changed then
		settings.debanding = checked
        uniforms_changed = true
	end

	if uniforms_changed then
		output_pp.init()
		uniforms_changed = false
	end

	imgui.spacing()
end
