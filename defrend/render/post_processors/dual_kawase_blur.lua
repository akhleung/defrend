local render_targets	= require "defrend.render.resources.render_targets"
local predicates		= require "defrend.render.resources.predicates"
local M = {}

function M.init()
end

-- TODO: Don't create closures every frame (this will require the draw options to be passed in some other way).
--       Maybe LuaJIT is already optimizing away these closures though.
function M.update(settings, draw_options)
	local iterations = settings.iterations
	-- downsample
	render.enable_material("kawase_downsample_material")
	for _ = 1, iterations do
		render_targets.downsample_source_with(function (source, target)
			render.set_render_target(target)
			render.enable_texture("color_sampler", source, render_targets.POST_COLOR)
			render.draw(predicates.screen, draw_options)
			render.disable_texture("color_sampler")
		end)
	end
	render.disable_material()
	-- upsample
	render_targets.ping_pong()
	render.enable_material("kawase_upsample_material")
	for _ = 1, iterations do
		render_targets.upsample_target_with(function (source, target)
			render.set_render_target(target)
			render.enable_texture("color_sampler", source, render_targets.POST_COLOR)
			render.draw(predicates.screen, draw_options)
			render.disable_texture("color_sampler")
		end)
	end
	render.disable_material()
end

return M
