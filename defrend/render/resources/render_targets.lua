local settings = require "defrend.render.settings"

local M = {}

local full_targets
local qtr_targets

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
	local full_source = render.render_target(
		"full_1",
		{
			[graphics.BUFFER_TYPE_COLOR0_BIT] = rgba_params, -- color
		}
	)
	local full_target = render.render_target(
		"full_2",
		{
			[graphics.BUFFER_TYPE_COLOR0_BIT] = rgba_params, -- color
		}
	)
	local qtr_source = render.render_target(
		"qtr_1",
		{
			[graphics.BUFFER_TYPE_COLOR0_BIT] = {
				format = graphics.TEXTURE_FORMAT_RGBA,
				width = render.get_window_width() / 2,
				height = render.get_window_height() / 2,
			}
		}
	)
	local qtr_target = render.render_target(
		"qtr_2",
		{
			[graphics.BUFFER_TYPE_COLOR0_BIT] = {
				format = graphics.TEXTURE_FORMAT_RGBA,
				width = render.get_window_width() / 2,
				height = render.get_window_height() / 2,
			}
		}
	)

	M.shadow_map	= shadow_map
	M.g_buffer		= g_buffer
	M.l_buffer		= l_buffer
	M.full_source	= full_source
	M.full_target	= full_target
	M.qtr_source	= qtr_source
	M.qtr_target	= qtr_target

	full_targets	= { g_buffer, l_buffer, full_source, full_target }
	qtr_targets		= { qtr_source, qtr_target }
end

function M.set_resolution(w, h)
	for _, rt in ipairs(full_targets) do
		render.set_render_target_size(rt, w, h)
	end
	for _, rt in ipairs(qtr_targets) do
		render.set_render_target_size(rt, w / 2, h / 2)
	end
end

return M
