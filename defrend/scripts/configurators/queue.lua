local PENDING_POINT_LIGHTS = {}
local PENDING_SPOT_LIGHTS = {}

local point_lights_initialized = false
local spot_lights_initialized = false

local M = {}

function M.point_lights_initialized()
	return point_lights_initialized
end

function M.spot_lights_initialized()
	return spot_lights_initialized
end

function M.add_pending_point_light(f)
	if point_lights_initialized then
		f()
	end
	table.insert(PENDING_POINT_LIGHTS, f)
end

function M.add_pending_spot_light(f)
	if spot_lights_initialized then
		f()
	end
	table.insert(PENDING_SPOT_LIGHTS, f)
end

function M.init_pending_point_lights()
	for _, f in ipairs(PENDING_POINT_LIGHTS) do
		f()
	end
	PENDING_POINT_LIGHTS = {}
	point_lights_initialized = true
end

function M.init_pending_spot_lights()
	for _, f in ipairs(PENDING_SPOT_LIGHTS) do
		f()
	end
	PENDING_SPOT_LIGHTS = {}
	spot_lights_initialized = true
end

return M
