local settings			= require("defrend.render.settings")
local predicates		= require("defrend.render.resources.predicates")
local render_targets	= require("defrend.render.resources.render_targets")

local M = {}

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
	shadow_atlas_directional = {
		material = "copy_r_material",
		get_render_target = function ()
			return M.shadow_map
		end,
		attachment = render_targets.SHADOW_MAP_DEPTH,
	},
	ssao = {
		material = "copy_rgb_material",
		get_render_target = render_targets.get_post_source,
		attachment = render_targets.POST_COLOR,
	},
}

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
end

function M.set_shadow_map(shadow_map)
	M.shadow_map = shadow_map
end

return M
