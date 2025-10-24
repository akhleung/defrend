local render_targets	= require "defrend.render.resources.render_targets"
local predicates		= require "defrend.render.resources.predicates"
local all_settings		= require "defrend.render.settings"
local all_draw_options	= require "defrend.render.resources.draw_options"
local dual_kawase_blur	= require "defrend.render.post_processors.dual_kawase_blur"

local M = {}

local g_buffer
local l_buffer
function M.init()
	g_buffer = render_targets.get_g_buffer()
	l_buffer = render_targets.get_l_buffer()
end

function M.update(settings, draw_options)
	-- save the main (focused) render in a spare buffer
	render.set_render_target(l_buffer)
	render.enable_material("copy_material")
	render.enable_texture("input_sampler", render_targets.get_post_source(), graphics.BUFFER_TYPE_COLOR0_BIT)
	render.draw(predicates.screen)
	render.disable_texture("input_sampler")
	render.disable_material()
	-- create a blurred render to mix with the focused render
	dual_kawase_blur.update(all_settings.dual_kawase_blur, all_draw_options.dual_kawase_options)
	-- dilate the blurred render too
	render_targets.ping_pong()
	render.set_render_target(render_targets.get_post_target())
	render.enable_material("dilate_material")
	render.enable_texture("color_sampler", render_targets.get_post_source(), graphics.BUFFER_TYPE_COLOR0_BIT)
	render.draw(predicates.screen, all_draw_options.dilate_options)
	render.disable_texture("color_sampler")
	render.disable_material()
	-- mix the blurred render with the focused render
	render_targets.ping_pong()
	render.set_render_target(render_targets.get_post_target())
	render.enable_material("dof_material")
	render.enable_texture("depth_buffer", g_buffer, graphics.BUFFER_TYPE_DEPTH_BIT)
	render.enable_texture("focused_sampler", l_buffer, graphics.BUFFER_TYPE_COLOR0_BIT)
	render.enable_texture("blurred_sampler", render_targets.get_post_source(), graphics.BUFFER_TYPE_COLOR0_BIT)
	local params = draw_options.constants.params
	params.x = settings.focal_depth
	draw_options.constants.params = params
	render.draw(predicates.screen, draw_options)
	render.disable_texture("depth_buffer")
	render.disable_texture("focused_sampler")
	render.disable_texture("blurred_sampler")
	render.disable_material()
end

return M
