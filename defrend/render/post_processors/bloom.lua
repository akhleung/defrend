local render_targets	= require "defrend.render.resources.render_targets"
local predicates		= require "defrend.render.resources.predicates"
local M = {}

function M.init()
end

function M.update(settings, draw_options)
    render.set_render_target(render_targets.get_post_target())
    render.enable_material("bloom_material")
    render.enable_texture("color_sampler", render_targets.get_post_source(), graphics.BUFFER_TYPE_COLOR0_BIT)
    render.draw(predicates.screen, draw_options)
    render.disable_texture("color_sampler")
    render.disable_material()
end

return M
