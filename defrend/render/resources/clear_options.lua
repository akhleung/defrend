local M = {}

function M.init()
	local color_and_depth = {
		-- [graphics.BUFFER_TYPE_COLOR0_BIT] = vmath.vector4(
		--     sys.get_config_number("render.clear_color_red", 0),
		--     sys.get_config_number("render.clear_color_green", 0),
		--     sys.get_config_number("render.clear_color_blue", 0),
		--     sys.get_config_number("render.clear_color_alpha", 0)
		-- ),
		[graphics.BUFFER_TYPE_COLOR0_BIT]	= vmath.vector4(0),
		[graphics.BUFFER_TYPE_DEPTH_BIT]	= 1,
		[graphics.BUFFER_TYPE_STENCIL_BIT]	= 0
	}
	local color_only = {
		[graphics.BUFFER_TYPE_COLOR0_BIT]	= vmath.vector4(0),
	}
	local ssao = {
		[graphics.BUFFER_TYPE_COLOR0_BIT]	= vmath.vector4(1, 1, 1, 1),
		[graphics.BUFFER_TYPE_DEPTH_BIT]	= 1,
		[graphics.BUFFER_TYPE_STENCIL_BIT]	= 0
	}
	local shadows = {
		[graphics.BUFFER_TYPE_DEPTH_BIT]	= 1,
		[graphics.BUFFER_TYPE_STENCIL_BIT]	= 0
	}

	M.color_and_depth	= color_and_depth
	M.color_only		= color_only
	M.ssao				= ssao
	M.shadows			= shadows
end

return M
