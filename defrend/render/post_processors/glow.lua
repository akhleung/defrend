local render_targets	= require("defrend.render.resources.render_targets")
local predicates		= require("defrend.render.resources.predicates")
local dual_kawase_blur	= require("defrend.render.post_processors.dual_kawase_blur")
local settings			= require("defrend.render.settings").glow
local draw_options		= require("defrend.render.resources.draw_options").glow_options

local M = {}

local g_buffer
function M.init()
	g_buffer = render_targets.get_g_buffer()
end

function M.update()
	-- swap the main render to the spare buffer; source is now scratch
	render_targets.ping_pong_spare()
	-- multiply emissive strength and color from g-buffer to target
	render.set_render_target(render_targets.get_post_target())
	render.enable_material("glow_color_material")
	render.enable_texture("color_sampler", g_buffer, render_targets.G_BUFFER_ALBEDO)
	render.draw(predicates.screen)
	render.disable_texture("color_sampler")
	-- blur the emissive texture
	render_targets.ping_pong() -- swap glow texture to source and then blur it into target
	dual_kawase_blur.update(settings, draw_options)
	-- swap the main render back into source
	render_targets.ping_pong_spare()
	-- swap source (main render) and target (blurred glow texture)
	render_targets.ping_pong()
	-- blend the source (glow texture) onto the target (main render)
	render.set_render_target(render_targets.get_post_target())
	render.enable_material("copy_material")
	render.enable_state(graphics.STATE_BLEND)
	render.enable_texture("input_sampler", render_targets.get_post_source(), render_targets.POST_COLOR)
	render.draw(predicates.screen)
	render.disable_texture("input_sampler")
	render.disable_state(graphics.STATE_BLEND)
end

return M
