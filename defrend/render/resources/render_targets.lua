local predicates = require "defrend.render.resources.predicates"

local M = {}

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
local w, h

local function ldr_params(w, h)
	return {
		format	= graphics.TEXTURE_FORMAT_RGBA,
		width	= w,
		height	= h,
	}
end

local function hdr_params(w, h)
	return {
		format	= graphics.TEXTURE_FORMAT_RGBA16F,
		width	= w,
		height	= h,
	}
end

local function depth_params(w, h)
	return {
		format	= graphics.TEXTURE_FORMAT_DEPTH,
		width	= w,
		height	= h,
		flags	= render.TEXTURE_BIT,
	}
end

function M.init(blinn_phong)
	w, h = render.get_window_width(), render.get_window_height()
	-- g-buffer
	if blinn_phong then
		g_buffer = render.render_target("g_buffer", {
			[graphics.BUFFER_TYPE_COLOR0_BIT]	= ldr_params(w, h),   -- albedo + emissive
			[graphics.BUFFER_TYPE_COLOR1_BIT]	= ldr_params(w, h),   -- normal + specular
			[graphics.BUFFER_TYPE_DEPTH_BIT]	= depth_params(w, h), -- depth
		})
	else
		g_buffer = render.render_target("g_buffer", {
			[graphics.BUFFER_TYPE_COLOR0_BIT]	= ldr_params(w, h),   -- albedo + emissive
			[graphics.BUFFER_TYPE_COLOR1_BIT]	= ldr_params(w, h),   -- orm (occlusion, roughness, metalness)
			[graphics.BUFFER_TYPE_COLOR2_BIT]	= ldr_params(w, h),   -- normal + specular
			[graphics.BUFFER_TYPE_DEPTH_BIT]	= depth_params(w, h), -- depth
		})
	end
	-- spare target for misc
	spare = render.render_target("spare", {
		[graphics.BUFFER_TYPE_COLOR0_BIT]	= hdr_params(w, h),
	})
	-- full-sized post-processing targets
	source1 = render.render_target("source1", {
		[graphics.BUFFER_TYPE_COLOR0_BIT]	= hdr_params(w, h),
	})
	target1 = render.render_target("target1", {
		[graphics.BUFFER_TYPE_COLOR0_BIT]	= hdr_params(w, h),
	})
	-- quarter-sized post-processing targets
	source4 = render.render_target("source4", {
		[graphics.BUFFER_TYPE_COLOR0_BIT]	= hdr_params(w/2, h/2)
	})
	target4 = render.render_target("target4", {
		[graphics.BUFFER_TYPE_COLOR0_BIT]	= hdr_params(w/2, h/2)
	})
	-- sixteenth-sized post-processing targets
	source16 = render.render_target("source16", {
		[graphics.BUFFER_TYPE_COLOR0_BIT]	= hdr_params(w/4, h/4)
	})
	target16 = render.render_target("target16", {
		[graphics.BUFFER_TYPE_COLOR0_BIT]	= hdr_params(w/4, h/4)
	})
	-- sixtyfourth-sized post-processing targets
	source64 = render.render_target("source64", {
		[graphics.BUFFER_TYPE_COLOR0_BIT]	= hdr_params(w/8, h/8)
	})
	target64 = render.render_target("target64", {
		[graphics.BUFFER_TYPE_COLOR0_BIT]	= hdr_params(w/8, h/8)
	})

	source = source1
	target = target1

	full_targets		= { g_buffer, source1, target1, spare }
	quarter_targets		= { source4, target4 }
	sixteenth_targets	= { source16, target16 }
	sixtyfourth_targets	= { source64, target64 }

	sources	= { source1, source4, source16, source64 }
	targets	= { target1, target4, target16, target64 }
end

function M.set_resolution(nw, nh)
	w, h = nw, nh
	for _, rt in ipairs(full_targets) do
		render.set_render_target_size(rt, w, h)
	end
	for _, rt in ipairs(quarter_targets) do
		render.set_render_target_size(rt, w/2, h/2)
	end
	for _, rt in ipairs(sixteenth_targets) do
		render.set_render_target_size(rt, w/4, h/4)
	end
	for _, rt in ipairs(sixtyfourth_targets) do
		render.set_render_target_size(rt, w/8, h/8)
	end
	render.set_viewport(0, 0, w, h)
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

function M.get_spare()
	return spare
end

function M.ping_pong()
	source, sources, target, targets = target, targets, source, sources
end

function M.ping_pong_spare()
	source, sources[1], spare = spare, spare, source
end

function M.ping_pong_downsampled()
	local i = downsampling_level + 1
	sources[i], targets[i] = targets[i], sources[i]
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
	render.set_viewport(0, 0, w * scale, h * scale)
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
	render.set_viewport(0, 0, w * scale, h * scale)
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
	render.set_viewport(0, 0, w * scale, h * scale)
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
	render.set_viewport(0, 0, w * scale, h * scale)
	callback(this_target, next_target)
	source, target = next_source, next_target
	return true
end

function M.reset()
	scale = 1
	downsampling_level = 0
	render.set_viewport(0, 0, w * scale, h * scale)
	source, target = sources[1], targets[1]
end

M.G_BUFFER_ALBEDO		= graphics.BUFFER_TYPE_COLOR0_BIT
M.G_BUFFER_NORMAL		= graphics.BUFFER_TYPE_COLOR1_BIT
M.G_BUFFER_DEPTH		= graphics.BUFFER_TYPE_DEPTH_BIT

M.SPARE_COLOR			= graphics.BUFFER_TYPE_COLOR0_BIT

M.POST_COLOR			= graphics.BUFFER_TYPE_COLOR0_BIT

M.SHADOW_MAP_DEPTH		= graphics.BUFFER_TYPE_DEPTH_BIT

return M
