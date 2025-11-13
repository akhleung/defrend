local predicates		= require("defrend.render.resources.predicates")
local render_targets	= require("defrend.render.resources.render_targets")
local draw_options		= require("defrend.render.resources.draw_options")
local shadow_options	= draw_options.shadow_options
local ssao_options		= draw_options.ssao_options
local ssao_blur_options	= draw_options.ssao_blur_options

local M = {}

local model_predicate
local particle_predicate
local blob_shadow_predicate
local screen_predicate

local enable_material	= render.enable_material
local disable_material	= render.disable_material
local enable_texture	= render.enable_texture
local disable_texture	= render.disable_texture
local set_render_target	= render.set_render_target
local draw				= render.draw

local g_buffer
local get_post_source	= render_targets.get_post_source
local get_post_target	= render_targets.get_post_target
local ping_pong			= render_targets.ping_pong
local G_BUFFER_DEPTH	= render_targets.G_BUFFER_DEPTH
local G_BUFFER_NORMAL	= render_targets.G_BUFFER_NORMAL
local POST_COLOR		= render_targets.POST_COLOR

local SHADOW_MATERIAL			= hash("shadow_material")
local BLOB_SHADOW_MATERIAL		= hash("blob_shadow_material")
local PARTICLE_SHADOW_MATERIAL	= hash("particle_shadow_material")
local SSAO_MATERIAL				= hash("ssao_material")
local SSAO_BLUR_HORIZONTAL_MATERIAL	= hash("ssao_blur_horizontal_material")
local SSAO_BLUR_VERTICAL_MATERIAL	= hash("ssao_blur_vertical_material")
local SSAO_BLUR_HORIZONTAL_DEPTH_ONLY_MATERIAL = hash("ssao_blur_horizontal_depth_only_material")
local SSAO_BLUR_VERTICAL_DEPTH_ONLY_MATERIAL = hash("ssao_blur_vertical_depth_only_material")

local COLOR_SAMPLER = hash("color_sampler")
local DEPTH_BUFFER = hash("depth_buffer")
local NORMAL_SAMPLER = hash("normal_sampler")

function M.init()
	predicates.init()
	model_predicate			= predicates.model
	blob_shadow_predicate	= predicates.blob_shadow
	particle_predicate		= predicates.particle
	screen_predicate		= predicates.screen

	render_targets.init()
	g_buffer = render_targets.get_g_buffer()
end

function M.render_model_shadows()
	enable_material(SHADOW_MATERIAL)
	draw(model_predicate, shadow_options)
	disable_material()
end

function M.render_blob_shadows()
	enable_material(BLOB_SHADOW_MATERIAL)
	draw(blob_shadow_predicate, shadow_options)
	disable_material()
end

function M.render_particle_shadows()
	enable_material(PARTICLE_SHADOW_MATERIAL)
	draw(particle_predicate, shadow_options)
	disable_material()
end

function M.render_ssao()
	enable_material(SSAO_MATERIAL)
	enable_texture(DEPTH_BUFFER, g_buffer, G_BUFFER_DEPTH)
	enable_texture(NORMAL_SAMPLER, g_buffer, G_BUFFER_NORMAL)
	draw(screen_predicate, ssao_options)
	disable_texture(DEPTH_BUFFER)
	disable_texture(NORMAL_SAMPLER)
	disable_material()
end

function M.blur_ssao()
	set_render_target(get_post_target())
	enable_material(SSAO_BLUR_HORIZONTAL_MATERIAL)
	enable_texture(COLOR_SAMPLER, get_post_source(), POST_COLOR)
	enable_texture(DEPTH_BUFFER, g_buffer, G_BUFFER_DEPTH)
	enable_texture(NORMAL_SAMPLER, g_buffer, G_BUFFER_NORMAL)
	draw(screen_predicate, ssao_blur_options)
	disable_texture(COLOR_SAMPLER)
	disable_material()
	ping_pong()
	set_render_target(get_post_target())
	enable_material(SSAO_BLUR_VERTICAL_MATERIAL)
	enable_texture(COLOR_SAMPLER, get_post_source(), POST_COLOR)
	draw(screen_predicate, ssao_blur_options)
	disable_texture(COLOR_SAMPLER)
	disable_texture(DEPTH_BUFFER)
	disable_texture(NORMAL_SAMPLER)
	disable_material()
end

function M.blur_ssao_depth_only()
	set_render_target(get_post_target())
	enable_material(SSAO_BLUR_HORIZONTAL_DEPTH_ONLY_MATERIAL)
	enable_texture(COLOR_SAMPLER, get_post_source(), POST_COLOR)
	enable_texture(DEPTH_BUFFER, g_buffer, G_BUFFER_DEPTH)
	draw(screen_predicate, ssao_blur_options)
	disable_texture(COLOR_SAMPLER)
	disable_material()
	ping_pong()
	set_render_target(get_post_target())
	enable_material(SSAO_BLUR_VERTICAL_DEPTH_ONLY_MATERIAL)
	enable_texture(COLOR_SAMPLER, get_post_source(), POST_COLOR)
	draw(screen_predicate, ssao_blur_options)
	disable_texture(COLOR_SAMPLER)
	disable_texture(DEPTH_BUFFER)
	disable_material()
end

return M
