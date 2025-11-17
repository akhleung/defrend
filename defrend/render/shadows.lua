local settings = require "defrend.render.settings"
local shadow_settings = settings.shadow

local M = {}

local UP = vmath.vector3(0, 1, 0)
local RIGHT = vmath.vector3(1, 0, 0)
local MAX_NUM = 2000000000
local MIN_NUM = -2000000000
local LIGHT_FRUSTUMS
local Z_PADDING_FACTOR = settings.shadow.z_padding_factor
local get_minimal_bounding_box_for_camera_frustum
function M.init(fov, aspect, near, far)
	settings.shadow.partitions = {}
	settings.shadow.projections = {}
	settings.shadow.map_dimension = math.ceil(math.sqrt(#settings.shadow.cascade))
	settings.shadow.map_resolution = settings.shadow.atlas_resolution / settings.shadow.map_dimension
	settings.shadow.texel_size = 1 / settings.shadow.map_resolution
	local total_range = far - near
	for i = 1, #settings.shadow.cascade do
		far = near + total_range * settings.shadow.cascade[i]
		local y_offset = math.floor((i - 1) / settings.shadow.map_dimension) / settings.shadow.map_dimension -- * shadow.map_resolution
		local x_offset = ((i - 1) % settings.shadow.map_dimension) / settings.shadow.map_dimension -- * shadow.map_resolution
		settings.shadow.partitions[i] = vmath.vector4(x_offset, y_offset, far, settings.shadow.biases[i])
		settings.shadow.projections[i] = vmath.matrix4_perspective(fov, aspect, near, far)
		near = far
	end

	Z_PADDING_FACTOR = settings.shadow.z_padding_factor
	LIGHT_FRUSTUMS = {}
	for i = 1, #settings.shadow.cascade do
		LIGHT_FRUSTUMS[i] = get_minimal_bounding_box_for_camera_frustum(settings.shadow.projections[i])
	end
end

local world_center = vmath.vector3()
local directional_to = vmath.vector3()
local origin = vmath.vector4(0,0,0,1)
local get_light_view_mtx_and_camera_frustum
local get_texel_snapping_mtx
local pad, set_vec3

function M.refresh_shadows(cam_view, cam_proj, i)
	local mtx_light_view = get_light_view_mtx_and_camera_frustum(cam_view, cam_proj)
	local frustum = LIGHT_FRUSTUMS[i]
	-- extend the near plane of the light frustum to prevent clipping of shadows cast from outside the camera fov
	min_z = pad(frustum.min_z, frustum.max_z, Z_PADDING_FACTOR)
	local mtx_light_proj = vmath.matrix4_orthographic(frustum.min_x, frustum.max_x, frustum.min_y, frustum.max_y, min_z, frustum.max_z)
	local mtx_trans = get_texel_snapping_mtx(mtx_light_view, mtx_light_proj)
	return mtx_light_view, mtx_trans * mtx_light_proj
end

-- Given a desired camera frustum, find the smallest bounding box that will fit any rotation of said frustum. This
-- is a brute-force approach that rotates the camera in a sphere, calculates a bounding box for each rotation, and
-- returns the largest. I'm sure there's an analytical method for calculating this, but researching and implementing
-- it isn't currently a priority since this calculation will only be done occasionally (i.e., when the camera
-- projection changes).
local EYE = vmath.vector3(0)
local slices = 20
get_minimal_bounding_box_for_camera_frustum = function(cam_proj)
	local bbox = {
		min_x = 0, max_x = 0,
		min_y = 0, max_y = 0,
		min_z = 0, max_z = 0,
	}
	local delta = 360 / slices
	for pitch = -180, 180 - delta, delta do
		for yaw = -180, 180 - delta, delta do
			local r = vmath.euler_to_quat(pitch, yaw, 0)
			local mtx_view = vmath.matrix4_look_at(EYE, vmath.rotate(r, RIGHT), UP)
			local mtx_light_view, world_corners = get_light_view_mtx_and_camera_frustum(mtx_view, cam_proj)
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
			-- keep track of the largest frustum dimensions encountered so far
			if min_x < bbox.min_x then bbox.min_x = min_x end
			if max_x > bbox.max_x then bbox.max_x = max_x end
			if min_y < bbox.min_y then bbox.min_y = min_y end
			if max_y > bbox.max_y then bbox.max_y = max_y end
			if min_z < bbox.min_z then bbox.min_z = min_z end
			if max_z > bbox.max_z then bbox.max_z = max_z end
		end
	end
	return bbox
end

local ndc_corners = {
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
get_light_view_mtx_and_camera_frustum = function(cam_view, cam_proj)
	-- get the camera frustum in world space
	local mtx_inv = vmath.inv(cam_proj * cam_view)
	for i = 1, 8 do
		local world_corner = mtx_inv * ndc_corners[i]
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

pad = function(min, max, factor)
	local padding = (max - min) * factor
	return min - padding, max + padding
end

return M
