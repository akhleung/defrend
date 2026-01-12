local settings = require("defrend.render.settings")
local render_targets = require("defrend.render.resources.render_targets")

local M = {}

local HALF_PI = math.pi / 2

local NX = vmath.vector3(-1, 0, 0)
local PX = vmath.vector3(1, 0, 0)
local NY = vmath.vector3(0, -1, 0)
local PY = vmath.vector3(0, 1, 0)
local NZ = vmath.vector3(0, 0, -1)
local PZ = vmath.vector3(0, 0, 1)

local CUBE_FACES = { NX, PX, NY, PY, NZ, PZ }

local LIGHT_VIEWS
local LIGHT_PROJS

function M.init()
	LIGHT_VIEWS = {}
	LIGHT_PROJS = {}
	for _ = 1, settings.point_light_shadow.count do
		table.insert(LIGHT_VIEWS, {})
	end
end

function M.refresh(light, light_index)

	local center = go.get_world_position(light.url)
	local views = LIGHT_VIEWS[light_index]
	for face_index = 1, #CUBE_FACES do
		local face_dir = CUBE_FACES[face_index]
		local mtx_view = vmath.matrix4_look_at(center, face_dir, PY)
		views[face_index] = mtx_view
	end

	local radius = go.get_world_scale_uniform(light.url) * 0.5
	local mtx_proj = vmath.matrix4_perspective(HALF_PI, 1, 0.1, radius)
	LIGHT_PROJS[light_index] = mtx_proj

	return views, mtx_proj
end

return M
