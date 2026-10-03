local settings = require("defrend.render.settings").point_light

local M = {}

local HALF_PI = math.pi / 2
local FOV = HALF_PI

local NX = vmath.vector3(-1, 0, 0)
local PX = vmath.vector3(1, 0, 0)
local NY = vmath.vector3(0, -1, 0)
local PY = vmath.vector3(0, 1, 0)
local NZ = vmath.vector3(0, 0, -1)
local PZ = vmath.vector3(0, 0, 1)

local CUBE_FACES = { NX, PX, NY, PY, NZ, PZ }
local UP_VECTORS = { PY, PY, NZ, PZ, PY, PY }

local LIGHT_INDEX = {}
local LIGHT_MTXS = {}
local MTX_FREE_LIST = {}
local COUNT = 0

local PENDING = {}

local initialized = false

function M.init()
	LIGHT_INDEX = {}
	LIGHT_MTXS = {}
	MTX_FREE_LIST = {}
	COUNT = 0
	for i = 1, settings.shadow_caster_count do
		table.insert(LIGHT_MTXS, false)
		table.insert(MTX_FREE_LIST, i)
	end
	-- pad the fov to prevent artifacts when sampling at the edge of a map
	local fov_scale = 1 + 2 * (1 + 2 * settings.poisson_scale + settings.hash_scale) / settings.shadow_map_resolution
	FOV = HALF_PI * fov_scale

	for _, pending in ipairs(PENDING) do
		M.add_light(pending)
	end
	PENDING = {}

	initialized = true
end

function M.add_light(light_url)
	if not initialized then
		table.insert(PENDING, light_url)
	end
	if COUNT >= settings.shadow_caster_count then
		return 0
	end
	local i = MTX_FREE_LIST[#MTX_FREE_LIST]
	table.remove(MTX_FREE_LIST, #MTX_FREE_LIST)
	LIGHT_INDEX[light_url] = i
	LIGHT_MTXS[i] = { views = { false, false, false, false, false, false }, proj = false }
	COUNT = COUNT + 1
	return i
end

function M.remove_light(light_url)
	if COUNT <= 0 then
		return
	end
	local i = LIGHT_INDEX[light_url]
	if not i then
		return
	end
	LIGHT_INDEX[light_url] = nil
	if i > settings.shadow_caster_count then
		return
	end
	LIGHT_MTXS[i] = false
	table.insert(MTX_FREE_LIST, i)
	COUNT = COUNT - 1
end

---@param light_url url
---@return matrix4[] | nil, matrix4 | nil
function M.generate_matrices(light_url)
	local mtxs = LIGHT_MTXS[LIGHT_INDEX[light_url]]
	if not mtxs then
		return
	end

	local center = go.get_world_position(light_url)
	for face_index = 1, 6 do
		mtxs.views[face_index] = vmath.matrix4_look_at(center, center + CUBE_FACES[face_index], UP_VECTORS[face_index])
	end

	local radius = go.get_world_scale_uniform(light_url) * 0.5
	mtxs.proj = vmath.matrix4_perspective(FOV, 1, 0.1, radius)

	return mtxs.views, mtxs.proj
end

function M.for_each(f)
	for url, i in pairs(LIGHT_INDEX) do
		local mtxs = LIGHT_MTXS[i]
		if mtxs then
			f(url, i, mtxs.views, mtxs.proj)
		end
	end
end

return M
