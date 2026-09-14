local render_targets	= require("defrend.render.resources.render_targets")
local predicates		= require("defrend.render.resources.predicates")
local dof_blur_options	= require("defrend.render.resources.draw_options").dof_blur_options

local M = {}

local g_buffer
function M.init()
	g_buffer = render_targets.get_g_buffer()
end

function M.update(settings, draw_options)
	local params = draw_options.constants.params
	params.x = settings.focal_depth
	draw_options.constants.params = params
	-- keep a handle to the focused scene render
	local scene = render_targets.get_post_source()
	-- downsample main (focused) render; calculate and pack CoCs into the alpha channel
	render_targets.downsample_source_with(function (source, target)
		render.set_render_target(target)
		render.enable_material("dof_pack_coc_material")
		render.enable_texture("input_sampler", source, render_targets.POST_COLOR)
		render.enable_texture("depth_buffer", g_buffer, render_targets.G_BUFFER_DEPTH)
		render.draw(predicates.screen, draw_options)
		render.disable_texture("input_sampler")
		render.disable_texture("depth_buffer")
		render.disable_material()
	end)
	-- blur the downsampled render to mix with the focused render; this will also blur the CoCs
	render.set_render_target(render_targets.get_post_target())
	render.enable_material("dof_blur_material")
	render.enable_texture("input_sampler", render_targets.get_post_source(), render_targets.POST_COLOR)
	render.draw(predicates.screen, dof_blur_options)
	render.disable_texture("input_sampler")
	render.disable_material()
	-- upsample the blurred render while mixing with the focused render
	render_targets.upsample_target_with(function (source, target)
		render.set_render_target(target)
		render.enable_material("dof_resolve_material")
		render.enable_texture("focused_sampler", scene, render_targets.POST_COLOR)
		render.enable_texture("blurred_sampler", source, render_targets.POST_COLOR)
		render.draw(predicates.screen)
		render.disable_texture("focused_sampler")
		render.disable_texture("blurred_sampler")
		render.disable_material()
	end)
end

return M
