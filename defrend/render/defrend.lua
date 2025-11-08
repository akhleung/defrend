local settings = require "defrend.render.settings"
local M = {}

function M.screen_to_world(x, y)
    local cam = settings.scene_camera_url
    local inv_mtx = vmath.inv(camera.get_projection(cam) * camera.get_view(cam))
    local w, h    = window.get_size()

    local near = inv_mtx * vmath.vector4(x / w * 2 - 1, y / h * 2 - 1, -1, 1)
    local far  = inv_mtx * vmath.vector4(x / w * 2 - 1, y / h * 2 - 1, 1, 1)
    near       = near / near.w
    far        = far / far.w
    near       = vmath.vector3(near.x, near.y, near.z)
    far        = vmath.vector3(far.x, far.y, far.z)

    return near, far
end

return M
