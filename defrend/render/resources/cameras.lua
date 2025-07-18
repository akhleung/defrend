local M = {}

function M.init()
	local identity = vmath.matrix4()
	local scene_camera = {
		-- these will be updated in the render script's "set_view_projection" message handler
		view = identity,
		view_inv = identity,
		proj = identity,
		viewproj = identity,
		moved = true,
		-- these will be set by the set_scene_camera function below
		near = 0,
		far = 1,
		aspect = 1,
		fov = 0.67,
	}

	local screen_proj = vmath.matrix4_orthographic(-.5, .5, -.5, .5, -1, 1)
	local screen_camera = {
		view = identity,
		proj = screen_proj,
		viewproj = screen_proj * identity,
	}

	local gui_proj = vmath.matrix4_orthographic(0, render.get_window_width(), 0, render.get_window_height(), -1, 1)
	local gui_camera = {
		view = identity,
		proj = gui_proj,
		viewproj = gui_proj * identity,
	}

	M.scene_camera	= scene_camera
	M.screen_camera	= screen_camera
	M.gui_camera	= gui_camera
end

-- to be called by the light_and_shadow.script init function, which should be supplied with a scene camera url
function M.set_scene_camera_projection(fov, aspect, near, far)
    local scene_camera	= M.scene_camera
    scene_camera.fov	= fov
    scene_camera.aspect	= aspect
    scene_camera.near	= near
    scene_camera.far	= far
end

return M
