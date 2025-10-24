local render_targets	= require "defrend.render.resources.render_targets"
local predicates		= require "defrend.render.resources.predicates"
local M = {}

function M.init()
end

function M.update(settings, draw_options)
	local downsamples = settings.downsamples
	-- downsample
	for _ = 1, downsamples do
		render_targets.downsample_source()
	end
	-- blur horizontally
	render.set_render_target(render_targets.get_post_target())
	render.enable_material("gaussian_blur_horizontal_material")
	render.enable_texture("color_sampler", render_targets.get_post_source(), graphics.BUFFER_TYPE_COLOR0_BIT)
	render.draw(predicates.screen, draw_options)
	render.disable_texture("color_sampler")
	render.disable_material()
	-- blur vertically
	render_targets.ping_pong()
	render.set_render_target(render_targets.get_post_target())
	render.enable_material("gaussian_blur_vertical_material")
	render.enable_texture("color_sampler", render_targets.get_post_source(), graphics.BUFFER_TYPE_COLOR0_BIT)
	render.draw(predicates.screen, draw_options)
	render.disable_texture("color_sampler")
	render.disable_material()
	-- upsample
	for _ = 1, downsamples do
		render_targets.upsample_target()
	end
end

return M
