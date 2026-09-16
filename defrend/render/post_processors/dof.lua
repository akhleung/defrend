local dof_settings		= require("defrend.render.settings").dof
local dof_blur_options	= require("defrend.render.resources.draw_options").dof_blur_options
local render_targets	= require("defrend.render.resources.render_targets")
local predicates		= require("defrend.render.resources.predicates")

local M = {}

local g_buffer
function M.init()
	g_buffer = render_targets.get_g_buffer()
end

function M.update(settings, draw_options)
	local params = draw_options.constants.params
	params.x = settings.focal_depth
	draw_options.constants.params = params
	-- pack the focused render into the spare buffer with CoCs
	render.set_render_target(render_targets.get_post_spare())
	render.enable_material("dof_pack_coc_material")
	render.enable_texture("input_sampler", render_targets.get_post_source(), render_targets.POST_COLOR)
	render.enable_texture("depth_buffer", g_buffer, render_targets.G_BUFFER_DEPTH)
	render.draw(predicates.screen, draw_options)
	render.disable_texture("input_sampler")
	render.disable_texture("depth_buffer")
	render.disable_material()
	-- downsample the render with CoCs
	render_targets.ping_pong_spare() -- swap the render with CoCs into the postprocessing source buffer
	local downsamples = dof_settings.downsamples
	for _ = 1, downsamples do
		render_targets.downsample_source()
	end
	-- blur
	render.set_render_target(render_targets.get_post_target())
	render.enable_material("dof_blur_material")
	render.enable_texture("input_sampler", render_targets.get_post_source(), render_targets.POST_COLOR)
	render.draw(predicates.screen, dof_blur_options)
	render.disable_texture("input_sampler")
	render.disable_material()
	-- upsample
	for _ = 1, downsamples do
		render_targets.upsample_target()
	end
	-- resolve dof
	render_targets.ping_pong_spare() -- swap the focused render with CoCs back to the spare buffer
	render_targets.ping_pong() -- the upsample target is now the source
	render.set_render_target(render_targets.get_post_target())
	render.enable_material("dof_resolve_material")
	render.enable_texture("focused_sampler", render_targets.get_post_spare(), render_targets.POST_COLOR)
	render.enable_texture("blurred_sampler", render_targets.get_post_source(), render_targets.POST_COLOR)
	render.draw(predicates.screen)
	render.disable_texture("focused_sampler")
	render.disable_texture("blurred_sampler")
	render.disable_material()
end

return M
