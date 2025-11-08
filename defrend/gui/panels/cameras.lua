local settings = require "defrend.render.settings"
local SCRIPT_URL = "/defrend/lighting#shadow"

return function (self)

    local cam = settings.scene_camera_url
    local camera_changed = false
    
    imgui.text("Scene camera")

	local changed, value = imgui.input_float("Near Z", camera.get_near_z(cam), 1.0, 5.0)
	if changed then
        value = vmath.clamp(value, 1, camera.get_far_z(cam) - 1)
        camera.set_near_z(cam, value)
        camera_changed = true
	end

	local changed, value = imgui.input_float("Far Z", camera.get_far_z(cam), 1.0, 5.0)
	if changed then
        value = vmath.clamp(value, camera.get_near_z(cam) + 1, 100000)
        camera.set_far_z(cam, value)
        camera_changed = true
	end

	local changed, value = imgui.input_float("FOV", camera.get_fov(cam), 0.01, 0.05)
	if changed then
        camera.set_fov(cam, value)
        camera_changed = true
	end

	local changed, checked = imgui.checkbox("Auto aspect ratio", camera.get_auto_aspect_ratio(cam))
	if changed then
		camera.set_auto_aspect_ratio(cam, checked)
        camera_changed = true
	end

    if not checked then
        local changed, value = imgui.input_float("Aspect ratio", camera.get_aspect_ratio(cam), 0.01, 0.05)
        if changed then
            camera.set_aspect_ratio(cam, value)
            camera_changed = true
        end
    end

	if camera_changed then
		msg.post(SCRIPT_URL, "refresh")
	end

	imgui.spacing()
end
