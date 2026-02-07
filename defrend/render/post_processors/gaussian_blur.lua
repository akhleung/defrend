local render_targets	= require "defrend.render.resources.render_targets"
local predicates		= require "defrend.render.resources.predicates"
local M = {}

function M.init()
end

local h_options = { constants = render.constant_buffer() }
local v_options = { constants = render.constant_buffer() }
h_options.constants.delta = vmath.vector4(1, 0, 0, 0) ---@diagnostic disable-line: inject-field
v_options.constants.delta = vmath.vector4(0, 1, 0, 0) ---@diagnostic disable-line: inject-field

function M.update(settings, draw_options)

	local downsamples = settings.downsamples
	-- downsample
	for _ = 1, downsamples do
		render_targets.downsample_source()
	end

	render.enable_material("gaussian_blur_material")

	-- blur horizontally
	h_options.constants.params = draw_options.constants.params ---@diagnostic disable-line: inject-field
	render.set_render_target(render_targets.get_post_target())
	render.enable_texture("color_sampler", render_targets.get_post_source(), render_targets.POST_COLOR)
	render.draw(predicates.screen, h_options)
	render.disable_texture("color_sampler")

	render_targets.ping_pong()

	-- blur vertically
	v_options.constants.params = draw_options.constants.params ---@diagnostic disable-line: inject-field
	render.set_render_target(render_targets.get_post_target())
	render.enable_texture("color_sampler", render_targets.get_post_source(), render_targets.POST_COLOR)
	render.draw(predicates.screen, v_options)
	render.disable_texture("color_sampler")

	render.disable_material()

	-- upsample
	for _ = 1, downsamples do
		render_targets.upsample_target()
	end
end

return M
