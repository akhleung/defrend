local settings = require "render.settings"
local shadow_settings = settings.shadow

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

        ambient_color = settings.light.ambient_color,
        sun_color = settings.light.directional_color,
        sun_direction = settings.light.directional_to,

        moved = false,
    }
end

local world_center = vmath.vector3()
local world_center_vec4 = vmath.vector4(0, 0, 0, 1)
local directional_to = vmath.vector3()
local origin = vmath.vector4(0,0,0,1)
local get_light_view_mtx_and_camera_frustum
local get_texel_snapping_mtx
local pad, set_vec3

function M.refresh_shadows_half_stable(self, cam_proj)
    local mtx_light_view, world_corners = get_light_view_mtx_and_camera_frustum(self, cam_proj)
    -- calculate a precise bounding box around the camera frustum in the light's view space
    local min_x, max_x = MAX_NUM, MIN_NUM
    local min_y, max_y = MAX_NUM, MIN_NUM
    local min_z, max_z = MAX_NUM, MIN_NUM
    for i = 1, 8 do
        local light_corner = mtx_light_view * world_corners[i]
        min_x, max_x = math.min(min_x, light_corner.x), math.max(max_x, light_corner.x)
        min_y, max_y = math.min(min_y, light_corner.y), math.max(max_y, light_corner.y)
        min_z, max_z = math.min(min_z, light_corner.z), math.max(max_z, light_corner.z)
    end
    -- extend the near/far planes of the light frustum to prevent premature clipping of shadows
    min_z, max_z = pad(min_z, max_z, 2)
    -- use the aforementioned bounding box to create the light projection matrix
    local mtx_light_proj = vmath.matrix4_orthographic(min_x, max_x, min_y, max_y, min_z, max_z)
    local mtx_trans = get_texel_snapping_mtx(mtx_light_view, mtx_light_proj)
    return mtx_light_view, mtx_trans * mtx_light_proj
end

function M.refresh_shadows_stable(self, cam_proj)
    local mtx_light_view, world_corners, world_center = get_light_view_mtx_and_camera_frustum(self, cam_proj)
    -- get the max diameter and radius of the camera frustum
    local diameter = vmath.length(world_corners[1] - world_corners[8])
    local radius = diameter / 2
    set_vec3(world_center_vec4, world_center)
    local light_center = mtx_light_view * world_center_vec4
    -- calculate the light's view and projection matrices
    local width, depth = radius * 1.15, radius * 3
    local mtx_light_proj = vmath.matrix4_orthographic(
        light_center.x - width, light_center.x + width,
        light_center.y - width, light_center.y + width,
        light_center.z - depth, light_center.z + depth
    )
    local mtx_trans = get_texel_snapping_mtx(mtx_light_view, mtx_light_proj)
    return mtx_light_view, mtx_trans * mtx_light_proj
end

-- helper functions

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

get_light_view_mtx_and_camera_frustum = function(self, cam_proj)
    -- get the camera frustum in world space
    local mtx_inv = vmath.inv(cam_proj * self.camera.view)
    for i = 1, 8 do
        local model_corner = model_corners[i]
        local world_corner = mtx_inv * model_corner
        world_corner.x = world_corner.x / world_corner.w
        world_corner.y = world_corner.y / world_corner.w
        world_corner.z = world_corner.z / world_corner.w
        world_corner.w = 1
        world_corners[i] = world_corner
    end
    -- get the center of the camera frustum
    world_center.x, world_center.y, world_center.z = 0, 0, 0
    for i = 1, 8 do
        local world_corner = world_corners[i]
        world_center.x = world_center.x + world_corner.x
        world_center.y = world_center.y + world_corner.y
        world_center.z = world_center.z + world_corner.z
    end
    world_center = world_center / 8
    -- calculate the light's view matrix
    set_vec3(directional_to, settings.light.directional_to)
    local mtx_light_view = vmath.matrix4_look_at(world_center - directional_to, world_center, UP)
    return mtx_light_view, world_corners, world_center
end

local offset = vmath.vector3()
get_texel_snapping_mtx = function(mtx_light_view, mtx_light_proj)
    -- create a translation matrix to snap the light projection to the nearest texel
    local half_res = shadow_settings.map_resolution / 2
    local shadow_origin = mtx_light_proj * mtx_light_view * origin * half_res
    offset.x = (math.floor(shadow_origin.x) - shadow_origin.x) / half_res
    offset.y = (math.floor(shadow_origin.y) - shadow_origin.y) / half_res
    return vmath.matrix4_translation(offset)
end

set_vec3 = function(to, from)
    to.x, to.y, to.z = from.x, from.y, from.z
end
pad = function(min, max, padding) -- eh, maybe just add a hardcoded value
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

return M
