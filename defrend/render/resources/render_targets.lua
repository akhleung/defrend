local settings = require "defrend.render.settings"

local M = {}

local render_target_list

function M.init()
	local rgba_params = {
		format	= graphics.TEXTURE_FORMAT_RGBA,
		width	= render.get_window_width(),
		height	= render.get_window_height(),
	}
	local depth_params = {
		format	= graphics.TEXTURE_FORMAT_DEPTH,
		width	= render.get_window_width(),
		height	= render.get_window_height(),
		flags	= graphics.TEXTURE_USAGE_FLAG_SAMPLE, -- was render.TEXTURE_BIT
	}
	local shadow_depth_params = {
		format	= graphics.TEXTURE_FORMAT_DEPTH,
		width	= settings.shadow.atlas_resolution,
		height	= settings.shadow.atlas_resolution,
		flags	= graphics.TEXTURE_USAGE_FLAG_SAMPLE, -- was render.TEXTURE_BIT
	}

	local shadow_map = render.render_target(
		"shadow_map",
		{
			[graphics.BUFFER_TYPE_DEPTH_BIT] = shadow_depth_params,
		}
	)
	local g_buffer = render.render_target(
		"g_buffer",
		{
			[graphics.BUFFER_TYPE_COLOR0_BIT] = rgba_params, -- diffuse color
			[graphics.BUFFER_TYPE_COLOR1_BIT] = rgba_params, -- normal
			[graphics.BUFFER_TYPE_COLOR2_BIT] = rgba_params, -- specular & emissive
			[graphics.BUFFER_TYPE_DEPTH_BIT]  = depth_params, -- depth
		}
	)
	local l_buffer = render.render_target(
		"light_target",
		{
			[graphics.BUFFER_TYPE_COLOR0_BIT] = rgba_params, -- diffuse reflectance
			[graphics.BUFFER_TYPE_COLOR1_BIT] = rgba_params, -- specular reflectance
		}
	)
	local post_source = render.render_target(
		"post_left",
		{
			[graphics.BUFFER_TYPE_COLOR0_BIT] = rgba_params, -- color
		}
	)
	local post_target = render.render_target(
		"post_right",
		{
			[graphics.BUFFER_TYPE_COLOR0_BIT] = rgba_params, -- color
		}
	)

	M.shadow_map	= shadow_map
	M.g_buffer		= g_buffer
	M.l_buffer		= l_buffer
	M.post_source	= post_source
	M.post_target	= post_target

	render_target_list = { shadow_map, g_buffer, l_buffer, post_source, post_target }
end

function M.set_resolution(w, h)
	for _, rt in ipairs(render_target_list) do
		render.set_render_target_size(rt, w, h)
	end
end

return M
