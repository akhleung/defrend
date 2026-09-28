local settings = require("defrend.render.settings")

local M = {}

local HALF_PI = math.pi / 2

local NX = vmath.vector3(-1, 0, 0)
local PX = vmath.vector3(1, 0, 0)
local NY = vmath.vector3(0, -1, 0)
local PY = vmath.vector3(0, 1, 0)
local NZ = vmath.vector3(0, 0, -1)
local PZ = vmath.vector3(0, 0, 1)

local CUBE_FACES = { NX, PX, NY, PY, NZ, PZ }
local UP_VECTORS = { PY, PY, NZ, PZ, PY, PY }

local LIGHT_MTXS = {}
local MTX_FREE_LIST = {}
local COUNT = 0

function M.init()
	LIGHT_MTXS = {}
	MTX_FREE_LIST = {}
	COUNT = 0
	for i = 1, settings.point_light_shadow.count do
		table.insert(LIGHT_MTXS, false)
		table.insert(MTX_FREE_LIST, i)
	end
end

function M.add_light()
	if COUNT >= settings.point_light_shadow.count then
		return 0
	end
	local i = MTX_FREE_LIST[#MTX_FREE_LIST]
	table.remove(MTX_FREE_LIST, #MTX_FREE_LIST)
	LIGHT_MTXS[i] = { views = { false, false, false, false, false, false }, proj = false }
	COUNT = COUNT + 1
	return i
end

function M.remove_light(i)
	if COUNT <= 0 then
		return
	end
	LIGHT_MTXS[i] = false
	table.insert(MTX_FREE_LIST, i)
	COUNT = COUNT - 1
end

---@param light_url url
---@param i number
---@return matrix4[] | nil, matrix4 | nil
function M.generate_matrices(light_url, i)
	local mtxs = LIGHT_MTXS[i]
	if not mtxs then
		return
	end

	local center = go.get_world_position(light_url)
	for face_index = 1, 6 do
		mtxs.views[face_index] = vmath.matrix4_look_at(center, center + CUBE_FACES[face_index], UP_VECTORS[face_index])
	end

	local radius = go.get_world_scale_uniform(light_url) * 0.5
	mtxs.proj = vmath.matrix4_perspective(HALF_PI, 1, 0.1, radius)

	return mtxs.views, mtxs.proj
end

function M.for_each(f)
	for i, mtxs in ipairs(LIGHT_MTXS) do
		if mtxs then
			f(i, mtxs.views, mtxs.proj)
		end
	end
end

return M
