local predicates		= require("defrend.render.resources.predicates")
local geometry_options	= require("defrend.render.resources.draw_options").geometry_options
local render_targets	= require("defrend.render.resources.render_targets")

local M = {}

local model_predicate
local sprite_predicate
local billboard_predicate
local particle_predicate
local shadowless_particle_predicate
local decal_predicate
local skybox_predicate

local enable_material	= render.enable_material
local disable_material	= render.disable_material
local enable_texture	= render.enable_texture
local disable_texture	= render.disable_texture
local draw				= render.draw

local get_post_source = render_targets.get_post_source
local POST_COLOR = render_targets.POST_COLOR

local MODEL_MATERIAL				= hash("model_material")
local SPRITE_MATERIAL				= hash("sprite_material")
local BILLBOARD_MATERIAL			= hash("billboard_material")
local PARTICLE_MATERIAL				= hash("particle_material")
local SHADOWLESS_PARTICLE_MATERIAL	= hash("shadowless_particle_material")
local DECAL_MATERIAL				= hash("decal_material")
local SKYBOX_MATERIAL				= hash("skybox_material")

local DEPTH_BUFFER = hash("depth_buffer")

function M.init()
	predicates.init()
	model_predicate					= predicates.model
	sprite_predicate				= predicates.sprite
	billboard_predicate				= predicates.billboard
	particle_predicate				= predicates.particle
	shadowless_particle_predicate	= predicates.shadowless_particle
	decal_predicate					= predicates.decal
	skybox_predicate				= predicates.skybox
end

function M.render_models()
	enable_material(MODEL_MATERIAL)
	draw(model_predicate, geometry_options)
	disable_material()
end

function M.render_sprites()
    enable_material(SPRITE_MATERIAL)
    draw(sprite_predicate, geometry_options)
    disable_material()
end

function M.render_billboards()
	enable_material(BILLBOARD_MATERIAL)
	draw(billboard_predicate, geometry_options)
	disable_material()
end

function M.render_particles()
    enable_material(PARTICLE_MATERIAL)
    draw(particle_predicate, geometry_options)
    disable_material()
    enable_material(SHADOWLESS_PARTICLE_MATERIAL)
    draw(shadowless_particle_predicate, geometry_options)
    disable_material()
end

function M.render_decals()
    enable_material(DECAL_MATERIAL)
    enable_texture(DEPTH_BUFFER, get_post_source(), POST_COLOR)
    draw(decal_predicate, geometry_options)
    disable_texture(DEPTH_BUFFER)
    disable_material()
end

function M.render_skybox()
    enable_material(SKYBOX_MATERIAL)
    draw(skybox_predicate)
    disable_material()
end

return M
