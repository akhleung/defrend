local M = {}

local UP = vmath.vector3(0, 1, 0)
local MAX_NUM = 2000000000
local MIN_NUM = -2000000000
local identity = vmath.matrix4()
function M.setup_lights(self)
        -- for directional lighting and shadow mapping
        self.light = {
            view = identity,
            proj = identity,
            viewproj = identity,

            ambient_color = vmath.vector4(0.7, 0.7, 0.7, 1.0),
            sun_color = vmath.vector4(.95, .95, .95, 1.0),
            sun_direction = vmath.normalize(vmath.vector4(0.1, -1.5, 1, 1)),

            loose_bb = {
                min_x = 0, max_x = 0,
                min_y = 0, max_y = 0,
                min_z = 0, max_z = 0,
            },
            tight_bb = {
                min_x = 0, max_x = 0,
                min_y = 0, max_y = 0,
                min_z = 0, max_z = 0,
            },
            moved = false,
        }
end

local function adjust_min_max(min, max, adjust) -- eh, maybe just add a hardcoded value
    if min < 0 then
        min = min * adjust
    else
        min = min / adjust
    end
    if max < 0 then
        max = max / adjust
    else
        max = max * adjust
    end
    return min, max
end
local function inside(tight, loose)
    if tight.min_x < loose.min_x then return false end
    if tight.max_x > loose.max_x then return false end
    if tight.min_y < loose.min_y then return false end
    if tight.max_y > loose.max_y then return false end
    if tight.min_z < loose.min_z then return false end
    if tight.max_z > loose.max_z then return false end
    return true
end
local obj_corners = {
    vmath.vector4(-1, -1, -1, 1),
    vmath.vector4(-1, -1, 1, 1),
    vmath.vector4(-1, 1, -1, 1),
    vmath.vector4(-1, 1, 1, 1),
    vmath.vector4(1, -1, -1, 1),
    vmath.vector4(1, -1, 1, 1),
    vmath.vector4(1, 1, -1, 1),
    vmath.vector4(1, 1, 1, 1),
}
local wld_corners = {
    vmath.vector4(), -- placeholders for type checking and preallocation
    vmath.vector4(),
    vmath.vector4(),
    vmath.vector4(),
    vmath.vector4(),
    vmath.vector4(),
    vmath.vector4(),
    vmath.vector4(),
}
local center = vmath.vector3()
local adjust = 1.2 -- tweak as needed; higher values should prevent clipped/missing shadows from offscreen occluders
local sun_dir = vmath.vector3()
function M.refresh_shadows(self, near, far)
    -- skip the light frustum recalculations if the light and camera haven't moved
    if not (self.camera.moved or self.light.moved) then
        return
    end
    -- get the camera frustum in world space
    local mtx_inv = vmath.inv(self.camera.viewproj)
    for i = 1, 8 do
        local corner = mtx_inv * obj_corners[i]
        corner = corner / corner.w
        corner.w = 1
        wld_corners[i] = corner
    end

    -- get the center of the camera frustum
    center.x, center.y, center.z = 0, 0, 0
    for i = 1, 8 do
        local corner = wld_corners[i]
        center.x = center.x + corner.x
        center.y = center.y + corner.y
        center.z = center.z + corner.z
    end
    center = center / 8
    -- calculate the light's view matrix
    sun_dir.x = self.light.sun_direction.x
    sun_dir.y = self.light.sun_direction.y
    sun_dir.z = self.light.sun_direction.z
    local mtx_light_view = vmath.matrix4_look_at(center - sun_dir, center, UP)
    -- calculate a precise bounding box around the camera frustum in light view space
    local min_x = MAX_NUM
    local max_x = MIN_NUM
    local min_y = MAX_NUM
    local max_y = MIN_NUM
    local min_z = MAX_NUM
    local max_z = MIN_NUM
    for i = 1, 8 do
        local lvc = mtx_light_view * wld_corners[i]
        min_x = math.min(min_x, lvc.x)
        max_x = math.max(max_x, lvc.x)
        min_y = math.min(min_y, lvc.y)
        max_y = math.max(max_y, lvc.y)
        min_z = math.min(min_z, lvc.z)
        max_z = math.max(max_z, lvc.z)
    end
    local tight_bb = self.light.tight_bb
    local loose_bb = self.light.loose_bb
    tight_bb.min_x = min_x
    tight_bb.max_x = max_x
    tight_bb.min_y = min_y
    tight_bb.max_y = max_y
    tight_bb.min_z = min_z
    tight_bb.max_z = max_z
    -- if the precise bounding box of the view frustum is still inside the expanded box, then no need to update
    if inside(tight_bb, loose_bb) then
        return
    end
    -- otherwise loosen the bounding box to avoid clipping visible shadows from occluders outside the frustum
    min_x, max_x = adjust_min_max(min_x, max_x, adjust)
    min_y, max_y = adjust_min_max(min_y, max_y, adjust)
    min_z, max_z = adjust_min_max(min_z, max_z, adjust)
    loose_bb.min_x = min_x
    loose_bb.max_x = max_x
    loose_bb.min_y = min_y
    loose_bb.max_y = max_y
    loose_bb.min_z = min_z
    loose_bb.max_z = max_z
    -- use the aforementioned bounding box to create the light projection matrix
    local mtx_light_proj = vmath.matrix4_orthographic(min_x, max_x, min_y, max_y, min_z, max_z)
    return mtx_light_view, mtx_light_proj
end

return M