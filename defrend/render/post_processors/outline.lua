local render_targets	= require "defrend.render.resources.render_targets"
local predicates		= require "defrend.render.resources.predicates"
local M = {}

local g_buffer
function M.init()
	g_buffer = render_targets.get_g_buffer()
end

function M.update(settings, draw_options)
    render.set_render_target(render_targets.get_post_target())
    render.enable_material("outline_material")
    render.enable_texture("depth_buffer", g_buffer, graphics.BUFFER_TYPE_DEPTH_BIT)
    render.enable_texture("color_sampler", render_targets.get_post_source(), graphics.BUFFER_TYPE_COLOR0_BIT)
    render.enable_texture("normal_sampler", g_buffer, graphics.BUFFER_TYPE_COLOR1_BIT)
    render.draw(predicates.screen, draw_options)
    render.disable_texture("depth_buffer")
    render.disable_texture("color_sampler")
    render.disable_texture("normal_sampler")
    render.disable_material()
end

return M
