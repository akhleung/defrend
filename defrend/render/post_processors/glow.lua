local render_targets	= require "defrend.render.resources.render_targets"
local predicates		= require "defrend.render.resources.predicates"
local dual_kawase_blur	= require "defrend.render.post_processors.dual_kawase_blur"
local M = {}

local g_buffer
function M.init()
	g_buffer = render_targets.get_g_buffer()
end

function M.update(settings, draw_options)
	-- save the main render in a spare buffer
	render.set_render_target(render_targets.get_post_spare())
	render.enable_material("copy_material")
	render.enable_texture("input_sampler", render_targets.get_post_source(), render_targets.POST_COLOR)
	render.draw(predicates.screen)
	render.disable_texture("input_sampler")
	render.disable_material()
	-- multiply emissive strength and color
	render.set_render_target(render_targets.get_post_target())
	render.enable_material("glow_color_material")
	render.enable_texture("glow_sampler", g_buffer, render_targets.G_BUFFER_SPEC_GLOW)
	render.enable_texture("color_sampler", g_buffer, render_targets.G_BUFFER_DIFFUSE)
	render.draw(predicates.screen)
	render.disable_texture("glow_sampler")
	render.disable_texture("color_sampler")
	render.disable_material()
	-- blur the emissive texture
	render_targets.ping_pong()
	dual_kawase_blur.update(settings, draw_options)
	-- swap the blurred emissive texture to the source and copy the saved main render back to the target
	render_targets.ping_pong()
	render.set_render_target(render_targets.get_post_target())
	render.enable_material("copy_material")
	render.enable_texture("input_sampler", render_targets.get_post_spare(), render_targets.POST_COLOR)
	render.draw(predicates.screen)
	render.disable_texture("input_sampler")
	-- add the blurred emissive texture to the main render
	render.enable_state(graphics.STATE_BLEND)
	render.enable_texture("input_sampler", render_targets.get_post_source(), render_targets.POST_COLOR)
	render.draw(predicates.screen)
	render.disable_texture("input_sampler")
	render.disable_material()
	render.disable_state(graphics.STATE_BLEND)
end

return M
