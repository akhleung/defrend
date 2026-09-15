local render_targets	= require("defrend.render.resources.render_targets")
local predicates		= require("defrend.render.resources.predicates")
local dof_blur_options	= require("defrend.render.resources.draw_options").dof_blur_options

local M = {}

local g_buffer
local blur_target
local coc_target
function M.init()
	g_buffer = render_targets.get_g_buffer()
	coc_target = render.render_target("coc_target", {
		[graphics.BUFFER_TYPE_COLOR0_BIT] = {
			format	= graphics.TEXTURE_FORMAT_R16F,
			width	= render.get_window_width() / 2,
			height	= render.get_window_height() / 2,
		},
	})
	blur_target = render.render_target("blur_target", {
		[graphics.BUFFER_TYPE_COLOR0_BIT] = {
			format	= graphics.TEXTURE_FORMAT_RGBA,
			width	= render.get_window_width() / 2,
			height	= render.get_window_height() / 2,
		},
		[graphics.BUFFER_TYPE_COLOR1_BIT] = {
			format	= graphics.TEXTURE_FORMAT_RGBA,
			width	= render.get_window_width() / 2,
			height	= render.get_window_height() / 2,
		},
	})
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
	-- keep a handle to the downsampled scene
	local downsampled = render_targets.get_post_source()
	-- dilate CoCs
	render.set_render_target(coc_target)
	render.enable_material("dof_dilate_coc_material")
	render.enable_texture("downsampled_sampler", downsampled, render_targets.POST_COLOR)
	render.draw(predicates.screen)
	render.disable_texture("downsampled_sampler")
	render.disable_material()
	-- blur the downsampled render to mix with the focused render; this will also blur the CoCs
	-- render.set_render_target(render_targets.get_post_target())
	render.set_render_target(blur_target)
	render.enable_material("dof_blur_material")
	render.enable_texture("input_sampler", downsampled, render_targets.POST_COLOR)
	render.draw(predicates.screen, dof_blur_options)
	render.disable_texture("input_sampler")
	render.disable_material()
	-- upsample the blurred render while mixing with the focused render
	render_targets.upsample_target_with(function (_, target)
		render.set_render_target(target)
		render.enable_material("dof_resolve_material")
		render.enable_texture("focused_sampler", scene, render_targets.POST_COLOR)
		render.enable_texture("downsampled_sampler", downsampled, render_targets.POST_COLOR)
		render.enable_texture("dilated_coc_sampler", coc_target, graphics.BUFFER_TYPE_COLOR0_BIT)
		render.enable_texture("blurred_near_sampler", blur_target, graphics.BUFFER_TYPE_COLOR0_BIT)
		render.enable_texture("blurred_far_sampler", blur_target, graphics.BUFFER_TYPE_COLOR1_BIT)
		render.draw(predicates.screen)
		render.disable_texture("focused_sampler")
		render.disable_texture("downsampled_sampler")
		render.disable_texture("dilated_coc_sampler")
		render.disable_texture("blurred_near_sampler")
		render.disable_texture("blurred_far_sampler")
		render.disable_material()
	end)
end

return M
