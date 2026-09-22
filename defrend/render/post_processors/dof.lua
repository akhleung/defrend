local render_targets	= require("defrend.render.resources.render_targets")
local predicates		= require("defrend.render.resources.predicates")
local settings			= require("defrend.render.settings").dof
local coc_draw_options	= require("defrend.render.resources.draw_options").dof_coc_options
local blur_draw_options	= require("defrend.render.resources.draw_options").dof_blur_options

local M = {}

local g_buffer
function M.init()
	g_buffer = render_targets.get_g_buffer()
end

function M.update()
	local params = coc_draw_options.constants.params
	params.x = settings.focal_depth
	coc_draw_options.constants.params = params
	-- pack the focused render into the spare buffer with CoCs
	render.set_render_target(render_targets.get_post_spare())
	render.enable_material("dof_pack_coc_material")
	render.enable_texture("input_sampler", render_targets.get_post_source(), render_targets.POST_COLOR)
	render.enable_texture("depth_buffer", g_buffer, render_targets.G_BUFFER_DEPTH)
	render.draw(predicates.screen, coc_draw_options)
	render.disable_texture("input_sampler")
	render.disable_texture("depth_buffer")
	render.disable_material()
	-- downsample the render with CoCs
	render_targets.ping_pong_spare() -- swap the focused render with CoCs into the postprocessing source buffer
	local downsamples = settings.downsamples
	for _ = 1, downsamples do
		render_targets.downsample_source()
	end
	-- blur the render and dilate the CoCs
	render.set_render_target(render_targets.get_post_target())
	render.enable_material("dof_blur_material")
	render.enable_texture("input_sampler", render_targets.get_post_source(), render_targets.POST_COLOR)
	render.draw(predicates.screen, blur_draw_options)
	render.disable_texture("input_sampler")
	render.disable_material()
	-- resolve focused and blurred renders using the dilated CoCs
	local downsampled_target = render_targets.get_post_target() -- save a handle to the blurred, downsampled target
	render_targets.reset() -- skip the upsampling and reset the target back to the full-resolution textur
	render.set_render_target(render_targets.get_post_target())
	render.enable_material("dof_resolve_material")
	render.enable_texture("focused_sampler", render_targets.get_post_source(), render_targets.POST_COLOR)
	render.enable_texture("blurred_sampler", downsampled_target, render_targets.POST_COLOR)
	render.draw(predicates.screen, blur_draw_options)
	render.disable_texture("focused_sampler")
	render.disable_texture("blurred_sampler")
	render.disable_material()
end

return M
