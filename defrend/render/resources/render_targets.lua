local settings = require "defrend.render.settings"

local M = {}

local full_targets
local quarter_targets

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
	local source1 = render.render_target(
		"source1",
		{
			[graphics.BUFFER_TYPE_COLOR0_BIT] = rgba_params, -- color
		}
	)
	local target1 = render.render_target(
		"target1",
		{
			[graphics.BUFFER_TYPE_COLOR0_BIT] = rgba_params, -- color
		}
	)
	local source4 = render.render_target(
		"source4",
		{
			[graphics.BUFFER_TYPE_COLOR0_BIT] = {
				format = graphics.TEXTURE_FORMAT_RGBA,
				width = render.get_window_width() / 2,
				height = render.get_window_height() / 2,
			}
		}
	)
	local target4 = render.render_target(
		"target4",
		{
			[graphics.BUFFER_TYPE_COLOR0_BIT] = {
				format = graphics.TEXTURE_FORMAT_RGBA,
				width = render.get_window_width() / 2,
				height = render.get_window_height() / 2,
			}
		}
	)
	local source16 = render.render_target(
		"source16",
		{
			[graphics.BUFFER_TYPE_COLOR0_BIT] = {
				format = graphics.TEXTURE_FORMAT_RGBA,
				width = render.get_window_width() / 4,
				height = render.get_window_height() / 4,
			}
		}
	)
	local target16 = render.render_target(
		"target16",
		{
			[graphics.BUFFER_TYPE_COLOR0_BIT] = {
				format = graphics.TEXTURE_FORMAT_RGBA,
				width = render.get_window_width() / 4,
				height = render.get_window_height() / 4,
			}
		}
	)
	local source64 = render.render_target(
		"source64",
		{
			[graphics.BUFFER_TYPE_COLOR0_BIT] = {
				format = graphics.TEXTURE_FORMAT_RGBA,
				width = render.get_window_width() / 8,
				height = render.get_window_height() / 8,
			}
		}
	)
	local target64 = render.render_target(
		"target64",
		{
			[graphics.BUFFER_TYPE_COLOR0_BIT] = {
				format = graphics.TEXTURE_FORMAT_RGBA,
				width = render.get_window_width() / 8,
				height = render.get_window_height() / 8,
			}
		}
	)

	M.shadow_map	= shadow_map
	M.g_buffer		= g_buffer
	M.l_buffer		= l_buffer
	M.source1		= source1
	M.target1		= target1
	M.source4		= source4
	M.target4		= target4
	M.source16		= source16
	M.target16		= target16
	M.source64		= source64
	M.target64		= target64

	full_targets		= { g_buffer, l_buffer, source1, target1 }
	quarter_targets		= { source4, target4 }
	sixteenth_targets	= { source16, target16 }
	sixtyfourth_targets	= { source64, target64 }
end

function M.set_resolution(w, h)
	for _, rt in ipairs(full_targets) do
		render.set_render_target_size(rt, w, h)
	end
	for _, rt in ipairs(quarter_targets) do
		render.set_render_target_size(rt, w / 2, h / 2)
	end
	for _, rt in ipairs(sixteenth_targets) do
		render.set_render_target_size(rt, w / 4, h / 4)
	end
	for _, rt in ipairs(sixtyfourth_targets) do
		render.set_render_target_size(rt, w / 8, h / 8)
	end
end

return M
