local settings			= require("defrend.render.settings")
local predicates		= require("defrend.render.resources.predicates")
local render_targets	= require("defrend.render.resources.render_targets")

local visualizations = {
	g_albedo = {
		material = "copy_rgb_material",
		get_render_target = render_targets.get_g_buffer,
		attachment = render_targets.G_BUFFER_ALBEDO,
	},
	g_normals = {
		material = "copy_rgb_material",
		get_render_target = render_targets.get_g_buffer,
		attachment = render_targets.G_BUFFER_NORMAL,
	},
	g_specular = {
		material = "copy_a_material",
		get_render_target = render_targets.get_g_buffer,
		attachment = render_targets.G_BUFFER_NORMAL,
	},
	g_emissive = {
		material = "copy_a_material",
		get_render_target = render_targets.get_g_buffer,
		attachment = render_targets.G_BUFFER_ALBEDO,
	},
	g_depth = {
		material = "copy_r_material",
		get_render_target = render_targets.get_g_buffer,
		attachment = render_targets.G_BUFFER_DEPTH,
	},
	reflectance_diffuse = {
		material = "copy_rgb_material",
		get_render_target = render_targets.get_post_spare,
		attachment = render_targets.POST_COLOR,
	},
	reflectance_specular = {
		material = "copy_a_material",
		get_render_target = render_targets.get_post_spare,
		attachment = render_targets.POST_COLOR,
	},
	shadow_atlas = {
		material = "copy_r_material",
		get_render_target = render_targets.get_shadow_map,
		attachment = render_targets.SHADOW_MAP_DEPTH,
	},
	ssao = {
		material = "copy_rgb_material",
		get_render_target = render_targets.get_post_source,
		attachment = render_targets.POST_COLOR,
	},
}

local M = {}

function M.update()
	render.set_render_target(render.RENDER_TARGET_DEFAULT) ---@diagnostic disable-line: param-type-mismatch
	local v = visualizations[settings.visualize.option]
	if not v then
		return
	end
	render.enable_material(v.material)
	render.enable_texture("input_sampler", v.get_render_target(), v.attachment)
	render.draw(predicates.screen)
	render.disable_texture("input_sampler")
	render.disable_material()
end

return M
