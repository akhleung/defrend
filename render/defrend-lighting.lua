local settings = require "render.settings"
local light_settings = settings.light
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

    self.bounding_spheres = {}
    for i = 1, #settings.shadow.cascade do
        self.bounding_spheres[i] = {
            -- initialize the tight bounding sphere to be bigger, so that we force a recalculation in the first render
            tight = {
                center = vmath.vector3(),
                radius = 1,
            },
            loose = {
                center = vmath.vector3(),
                radius = 0,
            },
        }
    end
end

local function set_vec3(to, from)
    to.x, to.y, to.z = from.x, from.y, from.z
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
local depth_padding = 2 -- higher values should prevent clipped/missing shadows from occluders in front of the light frustum
local directional_to = vmath.vector3()
local sample_point = vmath.vector4(0,0,0,1)
function M.refresh_shadows(self, cam_proj, i)
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
    set_vec3(directional_to, settings.light.directional_to)
    local mtx_light_view = vmath.matrix4_look_at(center - directional_to, center, UP)
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
    min_z, max_z = pad(min_z, max_z, depth_padding)
    -- use the aforementioned bounding box to create the light projection matrix
    local mtx_light_proj = vmath.matrix4_orthographic(min_x, max_x, min_y, max_y, min_z, max_z)
    -- put a point in the light's clip space and use it to get the offset for snapping shadows to the nearest texel
    local shadow_point = mtx_light_proj * mtx_light_view * sample_point
    local shadow_point_x = shadow_point.x / shadow_point.w
    local shadow_point_y = shadow_point.y / shadow_point.w
    local texel_size_x = settings.shadow.map_resolution / (max_x - min_x)
    local texel_size_y = settings.shadow.map_resolution / (max_y - min_y)
    local nearest_texel_center_x = math.floor(shadow_point_x / texel_size_x) * texel_size_x + texel_size_x / 2
    local nearest_texel_center_y = math.floor(shadow_point_y / texel_size_y) * texel_size_y + texel_size_y / 2
    local offset_x = nearest_texel_center_x - shadow_point_x
	local offset_y = nearest_texel_center_y - shadow_point_y
    -- adjust the light's projection matrix to do the texel snapping
    mtx_light_proj.m03 = mtx_light_proj.m03 + offset_x
    mtx_light_proj.m13 = mtx_light_proj.m13 + offset_y
    -- return the matrices
    return mtx_light_view, mtx_light_proj
end

local diff = vmath.vector3()
local function inside(small_sphere, big_sphere)
    local bc, sc = big_sphere.center, small_sphere.center
    diff.x, diff.y, diff.z = bc.x - sc.x, bc.y - sc.y, bc.z - sc.z
    local dist_sqr = vmath.length_sqr(diff)
    local dr = big_sphere.radius - small_sphere.radius
    return dist_sqr < dr * dr
end
local function set_sphere(sphere, center, radius)
    set_vec3(sphere.center, center)
    sphere.radius = radius
end
local center = vmath.vector3()
local directional_to = vmath.vector3()
function M.refresh_shadows2(self, cam_proj, i)
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
        world_corners[i] = world_corner
    end
    -- get the max diameter and radius of the camera frustum
    local diameter = math.ceil(vmath.length(world_corners[1] - world_corners[8]))
    local radius = diameter / 2
    -- get the center of the camera frustum
    center.x, center.y, center.z = 0, 0, 0
    for i = 1, 8 do
        local world_corner = world_corners[i]
        center.x = center.x + world_corner.x
        center.y = center.y + world_corner.y
        center.z = center.z + world_corner.z
    end
    center = center / 8
    -- fetch out camera frustum bounding spheres calculated in the previous update
    local tight_sphere = self.bounding_spheres[i].tight
    local loose_sphere = self.bounding_spheres[i].loose
    -- set the tight bounding sphere to the current frustum; skip the refresh if it's still inside the loose sphere
    set_sphere(tight_sphere, center, radius)
    if inside(tight_sphere, loose_sphere) then
        return
    end
    -- otherwise update the loose bounding sphere and save it for subsequent frames
    set_sphere(loose_sphere, center, radius * 1.5)
    -- calculate the light's view and projection matrices
    set_vec3(directional_to, settings.light.directional_to)
    local mtx_light_view = vmath.matrix4_look_at(center - (directional_to * diameter), center, UP)
    local width, depth = radius * 2.5, radius * 6
    local mtx_light_proj = vmath.matrix4_orthographic(
        center.x - width, center.x + width,
        center.y - width, center.y + width,
        center.z - depth, center.z + depth
    )
    return mtx_light_view, mtx_light_proj
end

return M
