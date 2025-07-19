local M = {}

function M.init()
	local clear_color_options = {
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
	local clear_ssao_options = {
		[graphics.BUFFER_TYPE_COLOR0_BIT]	= vmath.vector4(1, 1, 1, 1),
		[graphics.BUFFER_TYPE_DEPTH_BIT]	= 1,
		[graphics.BUFFER_TYPE_STENCIL_BIT]	= 0
	}
	local clear_shadow_buffers = {
		[graphics.BUFFER_TYPE_COLOR0_BIT]	= vmath.vector4(1, 1, 1, 1),
		[graphics.BUFFER_TYPE_DEPTH_BIT]	= 1,
		[graphics.BUFFER_TYPE_STENCIL_BIT]	= 0
	}

	M.clear_color_options	= clear_color_options
	M.clear_ssao_options	= clear_ssao_options
	M.clear_shadow_options	= clear_shadow_buffers
end

return M
