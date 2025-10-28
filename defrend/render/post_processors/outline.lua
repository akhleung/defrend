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
    render.enable_texture("depth_buffer", g_buffer, render_targets.G_BUFFER_DEPTH)
    render.enable_texture("color_sampler", render_targets.get_post_source(), render_targets.POST_COLOR)
    render.enable_texture("normal_sampler", g_buffer, render_targets.G_BUFFER_NORMAL)
    render.draw(predicates.screen, draw_options)
    render.disable_texture("depth_buffer")
    render.disable_texture("color_sampler")
    render.disable_texture("normal_sampler")
    render.disable_material()
end

return M
