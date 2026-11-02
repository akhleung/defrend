local settings = require "defrend.render.settings"
local M = {}

function M.screen_to_world(camera_url, x, y)
    local inv_mtx = vmath.inv(camera.get_projection(camera_url) * camera.get_view(camera_url))
    local w, h    = window.get_size()

    local near = inv_mtx * vmath.vector4(x / w * 2 - 1, y / h * 2 - 1, -1, 1)
    local far  = inv_mtx * vmath.vector4(x / w * 2 - 1, y / h * 2 - 1, 1, 1)
    near       = near / near.w
    far        = far / far.w
    near3      = vmath.vector3(near.x, near.y, near.z)
    far3       = vmath.vector3(far.x, far.y, far.z)

    return near3, far3
end

return M
