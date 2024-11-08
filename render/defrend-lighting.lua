local M = {}

local UP = vmath.vector3(0, 1, 0)
local MAX_NUM = 2000000000
local MIN_NUM = -2000000000
local identity = vmath.matrix4()
function M.setup_lights(self)
        -- for directional lighting and shadow mapping
        self.light = {
            view = identity, -- these will be recalculated for each camera frustum partition as needed
            proj = identity,
            viewproj = identity,

            ambient_color = vmath.vector4(0.7, 0.7, 0.7, 1.0),
            sun_color = vmath.vector4(.95, .95, .95, 1.0),
            sun_direction = vmath.normalize(vmath.vector4(1, -1.5, 1, 1)),

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

local function pad(min, max, padding) -- eh, maybe just add a hardcoded value
    if min < 0 then
        min = min * padding
    else
        min = min / padding
    end
    if max < 0 then
        max = max / padding
    else
        max = max * padding
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
local model_corners = {
    vmath.vector4(-1, -1, -1, 1),
    vmath.vector4(-1, -1, 1, 1),
    vmath.vector4(-1, 1, -1, 1),
    vmath.vector4(-1, 1, 1, 1),
    vmath.vector4(1, -1, -1, 1),
    vmath.vector4(1, -1, 1, 1),
    vmath.vector4(1, 1, -1, 1),
    vmath.vector4(1, 1, 1, 1),
}
local world_corners = {
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
local depth_padding = 6 -- higher values should prevent clipped/missing shadows from occluders in front of the light frustum
local lateral_padding = 2 -- necessary for blending discontinuities when sampling at the edge of a map
local sun_dir = vmath.vector3()
function M.refresh_shadows(self, cam_proj)
    -- skip the light frustum recalculations if the light and camera haven't moved
    if not (self.camera.moved or self.light.moved) then
        return
    end
    -- get the camera frustum in world space
    local mtx_inv = vmath.inv(cam_proj * self.camera.view)
    for i = 1, 8 do
        local model_corner = model_corners[i]
        local world_corner = mtx_inv * model_corner
        world_corner = world_corner / world_corner.w
        world_corner.w = 1
        world_corners[i] = world_corner
    end
    -- get the center of the camera frustum
    center.x, center.y, center.z = 0, 0, 0
    for i = 1, 8 do
        local world_corner = world_corners[i]
        center.x = center.x + world_corner.x
        center.y = center.y + world_corner.y
        center.z = center.z + world_corner.z
    end
    center = center / 8
    -- calculate the light's view matrix
    sun_dir.x = self.light.sun_direction.x
    sun_dir.y = self.light.sun_direction.y
    sun_dir.z = self.light.sun_direction.z
    local mtx_light_view = vmath.matrix4_look_at(center - sun_dir, center, UP)
    -- calculate a precise bounding box around the camera frustum in the light's view space
    local min_x = MAX_NUM
    local max_x = MIN_NUM
    local min_y = MAX_NUM
    local max_y = MIN_NUM
    local min_z = MAX_NUM
    local max_z = MIN_NUM
    for i = 1, 8 do
        local light_corner = mtx_light_view * world_corners[i]
        min_x = math.min(min_x, light_corner.x)
        max_x = math.max(max_x, light_corner.x)
        min_y = math.min(min_y, light_corner.y)
        max_y = math.max(max_y, light_corner.y)
        min_z = math.min(min_z, light_corner.z)
        max_z = math.max(max_z, light_corner.z)
    end
    local tight_bb = self.light.tight_bb
    local loose_bb = self.light.loose_bb -- an expanded bounding box calculated during a previous update
    tight_bb.min_x = min_x
    tight_bb.max_x = max_x
    tight_bb.min_y = min_y
    tight_bb.max_y = max_y
    tight_bb.min_z = min_z
    tight_bb.max_z = max_z
    -- if the precise bounding box of the view frustum is still inside the expanded box, then no need to update
    -- if inside(tight_bb, loose_bb) then
    --     return
    -- end
    -- otherwise loosen the bounding box to avoid clipping visible shadows from occluders outside the frustum
    -- min_x, max_x = pad(min_x, max_x, min_lateral_padding, max_lateral_padding)
    -- min_y, max_y = pad(min_y, max_y, min_lateral_padding, max_lateral_padding)
    -- extend the near/far planes of the light frustum to prevent premature clipping of shadows
    min_z, max_z = pad(min_z, max_z, depth_padding)
    -- save the expanded box for subsequent checks
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