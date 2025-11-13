local predicates		= require("defrend.render.resources.predicates")
local render_targets	= require("defrend.render.resources.render_targets")
local draw_options		= require("defrend.render.resources.draw_options")
local geometry_options	= draw_options.geometry_options
local lighting_options	= draw_options.lighting_options

local M = {}

local point_light_predicate
local spot_light_predicate
local screen_predicate

local enable_material	= render.enable_material
local disable_material	= render.disable_material
local enable_texture	= render.enable_texture
local disable_texture	= render.disable_texture
local set_render_target	= render.set_render_target
local draw				= render.draw

local g_buffer
local shadow_map
local get_post_source	= render_targets.get_post_source
local get_post_target	= render_targets.get_post_target
local get_post_spare	= render_targets.get_post_spare
local ping_pong			= render_targets.ping_pong
local G_BUFFER_ALBEDO	= render_targets.G_BUFFER_ALBEDO
local G_BUFFER_DEPTH	= render_targets.G_BUFFER_DEPTH
local G_BUFFER_NORMAL	= render_targets.G_BUFFER_NORMAL
local SHADOW_MAP_DEPTH	= render_targets.SHADOW_MAP_DEPTH
local POST_COLOR		= render_targets.POST_COLOR

local POINT_LIGHT_MATERIAL	= hash("point_light_material")
local SPOT_LIGHT_MATERIAL	= hash("spot_light_material")
local RESOLVE_LIGHTING_MATERIAL = hash("resolve_lighting_material")

local ALBEDO_SAMPLER = hash("albedo_sampler")
local DEPTH_BUFFER = hash("depth_buffer")
local NORMAL_SAMPLER = hash("normal_sampler")
local SSAO_SAMPLER = hash("ssao_sampler")
local SHADOW_SAMPLER = hash("shadow_sampler")
local LIGHT_SAMPLER = hash("light_sampler")

function M.init()
	predicates.init()
	point_light_predicate	= predicates.point_light
	spot_light_predicate	= predicates.spot_light
	screen_predicate		= predicates.screen

	render_targets.init()
	g_buffer = render_targets.get_g_buffer()
	shadow_map = render_targets.get_shadow_map()
end

function M.render_point_lights()
	enable_material(POINT_LIGHT_MATERIAL)
	draw(point_light_predicate, geometry_options)
	disable_material()
end

function M.render_spot_lights()
	enable_material(SPOT_LIGHT_MATERIAL)
	draw(spot_light_predicate, geometry_options)
	disable_material()
end

function M.resolve_lighting()
	set_render_target(get_post_target())
	enable_material(RESOLVE_LIGHTING_MATERIAL)
	enable_texture(DEPTH_BUFFER, g_buffer, G_BUFFER_DEPTH)
	enable_texture(ALBEDO_SAMPLER, g_buffer, G_BUFFER_ALBEDO)
	enable_texture(NORMAL_SAMPLER, g_buffer, G_BUFFER_NORMAL)
	enable_texture(SSAO_SAMPLER, get_post_source(), POST_COLOR)
	enable_texture(SHADOW_SAMPLER, shadow_map, SHADOW_MAP_DEPTH)
	enable_texture(LIGHT_SAMPLER, get_post_spare(), POST_COLOR)
	draw(screen_predicate, lighting_options)
	disable_texture(DEPTH_BUFFER)
	disable_texture(ALBEDO_SAMPLER)
	disable_texture(NORMAL_SAMPLER)
	disable_texture(SSAO_SAMPLER)
	disable_texture(SHADOW_SAMPLER)
	disable_texture(LIGHT_SAMPLER)
	disable_material()
end

return M
