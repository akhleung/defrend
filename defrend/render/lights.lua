local M = {}

local POINT_LIGHTS = {} -- store a list of all point lights, which will be sorted on every frame
local SPOT_LIGHTS = {} -- same for spot lights

local function add_light(T, l)
	T[l.url] = l
end

local function remove_light(T, l)
	T[l.url] = nil
end

local function for_each(T, f)
	for _, light in pairs(T) do
		f(light)
	end
end

function M.clear_point_lights()
	POINT_LIGHTS = {}
end

function M.add_point_light(light)
	return add_light(POINT_LIGHTS, light)
end

function M.remove_point_light(light)
	remove_light(POINT_LIGHTS, light)
end

function M.for_each_point_light(f)
	for_each(POINT_LIGHTS, f)
end

function M.clear_spot_lights()
	SPOT_LIGHTS = {}
end

function M.add_spot_light(light)
	return add_light(SPOT_LIGHTS, light)
end

function M.remove_spot_light(light)
	remove_light(SPOT_LIGHTS, light)
end

function M.for_each_spot_light(f)
	for_each(SPOT_LIGHTS, f)
end

M.POINT_LIGHTS = POINT_LIGHTS

return M
