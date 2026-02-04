local settings = require "defrend.render.settings"
local predicates = require "defrend.render.resources.predicates"

local M = {}

local shadow_map
local point_light_shadow_map
local g_buffer
local source1
local target1
local source4
local target4
local source16
local target16
local source64
local target64

local source
local target

local full_targets
local quarter_targets
local sixteenth_targets
local sixtyfourth_targets

local sources
local targets
local downsampling_level = 0 -- [0, 3]; scale is (1/(2^downsampling_level))^2
local scale = 1
local x, y
local sr

function M.init()
	x, y = render.get_window_width(), render.get_window_height()
	sr = settings.shadow.atlas_resolution
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
		width	= sr,
		height	= sr,
		flags	= graphics.TEXTURE_USAGE_FLAG_SAMPLE, -- was render.TEXTURE_BIT
	}

	shadow_map = render.render_target(
		"shadow_map",
		{
			[graphics.BUFFER_TYPE_DEPTH_BIT] = shadow_depth_params,
		}
	)
	point_light_shadow_map = render.render_target(
		"point_light_shadow_map",
		{
			[graphics.BUFFER_TYPE_DEPTH_BIT] = {
				format	= graphics.TEXTURE_FORMAT_DEPTH,
				width	= settings.point_light_shadow.map_resolution * 6,
				height	= settings.point_light_shadow.map_resolution * settings.point_light_shadow.count,
				flags	= graphics.TEXTURE_USAGE_FLAG_SAMPLE,
			}
		}
	)
	g_buffer = render.render_target(
		"g_buffer",
		{
			[graphics.BUFFER_TYPE_COLOR0_BIT] = rgba_params, -- albedo + emissive
			[graphics.BUFFER_TYPE_COLOR1_BIT] = rgba_params, -- normal + specular
			[graphics.BUFFER_TYPE_DEPTH_BIT]  = depth_params, -- depth
		}
	)
	source1 = render.render_target(
		"source1",
		{
			[graphics.BUFFER_TYPE_COLOR0_BIT] = rgba_params, -- color
		}
	)
	target1 = render.render_target(
		"target1",
		{
			[graphics.BUFFER_TYPE_COLOR0_BIT] = rgba_params, -- color
		}
	)
	spare = render.render_target(
		"spare",
		{
			[graphics.BUFFER_TYPE_COLOR0_BIT] = rgba_params, -- color
		}
	)
	source4 = render.render_target(
		"source4",
		{
			[graphics.BUFFER_TYPE_COLOR0_BIT] = {
				format = graphics.TEXTURE_FORMAT_RGBA,
				width = render.get_window_width() / 2,
				height = render.get_window_height() / 2,
			}
		}
	)
	target4 = render.render_target(
		"target4",
		{
			[graphics.BUFFER_TYPE_COLOR0_BIT] = {
				format = graphics.TEXTURE_FORMAT_RGBA,
				width = render.get_window_width() / 2,
				height = render.get_window_height() / 2,
			}
		}
	)
	source16 = render.render_target(
		"source16",
		{
			[graphics.BUFFER_TYPE_COLOR0_BIT] = {
				format = graphics.TEXTURE_FORMAT_RGBA,
				width = render.get_window_width() / 4,
				height = render.get_window_height() / 4,
			}
		}
	)
	target16 = render.render_target(
		"target16",
		{
			[graphics.BUFFER_TYPE_COLOR0_BIT] = {
				format = graphics.TEXTURE_FORMAT_RGBA,
				width = render.get_window_width() / 4,
				height = render.get_window_height() / 4,
			}
		}
	)
	source64 = render.render_target(
		"source64",
		{
			[graphics.BUFFER_TYPE_COLOR0_BIT] = {
				format = graphics.TEXTURE_FORMAT_RGBA,
				width = render.get_window_width() / 8,
				height = render.get_window_height() / 8,
			}
		}
	)
	target64 = render.render_target(
		"target64",
		{
			[graphics.BUFFER_TYPE_COLOR0_BIT] = {
				format = graphics.TEXTURE_FORMAT_RGBA,
				width = render.get_window_width() / 8,
				height = render.get_window_height() / 8,
			}
		}
	)

	source = source1
	target = target1

	full_targets		= { g_buffer, source1, target1, spare }
	quarter_targets		= { source4, target4 }
	sixteenth_targets	= { source16, target16 }
	sixtyfourth_targets	= { source64, target64 }

	sources	= { source1, source4, source16, source64 }
	targets	= { target1, target4, target16, target64 }
end

function M.set_resolution(w, h)
	x, y = w, h
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
	render.set_viewport(0, 0, w, h)
end

function M.set_shadow_map_resolution(res)
	if res == sr then return end
	sr = res
	render.set_render_target_size(M.get_shadow_map(), sr, sr)
end

function M.get_shadow_map()
	return shadow_map
end

function M.get_point_light_shadow_map()
	return point_light_shadow_map
end

function M.get_g_buffer()
	return g_buffer
end

function M.get_post_source()
	return source
end

function M.get_post_target()
	return target
end

function M.get_post_spare()
	return spare
end

function M.ping_pong()
	source, sources, target, targets = target, targets, source, sources
end

function M.downsample_source()
	if downsampling_level == #sources then
		return false
	end
	downsampling_level = downsampling_level + 1
	local this_source = sources[downsampling_level]
	local next_source = sources[downsampling_level + 1]
	local next_target = targets[downsampling_level + 1]
	scale = scale * 0.5
	render.enable_material("copy_material")
	render.set_viewport(0, 0, x * scale, y * scale)
	render.set_render_target(next_source)
	render.enable_texture("input_sampler", this_source, graphics.BUFFER_TYPE_COLOR0_BIT)
	render.draw(predicates.screen)
	render.disable_texture("input_sampler")
	render.disable_material()
	source, target = next_source, next_target
	return true
end

function M.upsample_target()
	if downsampling_level == 0 then
		scale = 1
		return false
	end
	local this_target = targets[downsampling_level + 1]
	local next_target = targets[downsampling_level]
	local next_source = sources[downsampling_level]
	downsampling_level = downsampling_level - 1
	scale = scale * 2
	render.enable_material("copy_material")
	render.set_viewport(0, 0, x * scale, y * scale)
	render.set_render_target(next_target)
	render.enable_texture("input_sampler", this_target, graphics.BUFFER_TYPE_COLOR0_BIT)
	render.draw(predicates.screen)
	render.disable_texture("input_sampler")
	render.disable_material()
	source, target = next_source, next_target
	return true
end

function M.downsample_source_with(callback)
	if downsampling_level == #sources then
		return false
	end
	downsampling_level = downsampling_level + 1
	local this_source = sources[downsampling_level]
	local next_source = sources[downsampling_level + 1]
	local next_target = targets[downsampling_level + 1]
	scale = scale * 0.5
	render.set_viewport(0, 0, x * scale, y * scale)
	callback(this_source, next_source)
	source, target = next_source, next_target
	return true
end

function M.upsample_target_with(callback)
	if downsampling_level == 0 then
		scale = 1
		return false
	end
	local this_target = targets[downsampling_level + 1]
	local next_target = targets[downsampling_level]
	local next_source = sources[downsampling_level]
	downsampling_level = downsampling_level - 1
	scale = scale * 2
	render.set_viewport(0, 0, x * scale, y * scale)
	callback(this_target, next_target)
	source, target = next_source, next_target
	return true
end

function M.reset()
	scale = 1
	source, target = sources[1], targets[1]
end

M.G_BUFFER_ALBEDO		= graphics.BUFFER_TYPE_COLOR0_BIT
M.G_BUFFER_NORMAL		= graphics.BUFFER_TYPE_COLOR1_BIT
M.G_BUFFER_DEPTH		= graphics.BUFFER_TYPE_DEPTH_BIT

M.POST_COLOR			= graphics.BUFFER_TYPE_COLOR0_BIT

M.SHADOW_MAP_DEPTH		= graphics.BUFFER_TYPE_DEPTH_BIT

return M
