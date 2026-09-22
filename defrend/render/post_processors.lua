local settings          = require("defrend.render.settings")
local render_targets	= require("defrend.render.resources.render_targets")

local outline			= require("defrend.render.post_processors.outline")
local gamma				= require("defrend.render.post_processors.gamma")
local glow				= require("defrend.render.post_processors.glow")
local bloom				= require("defrend.render.post_processors.bloom")
local kuwahara_blur		= require("defrend.render.post_processors.kuwahara_blur")
local gaussian_blur		= require("defrend.render.post_processors.gaussian_blur")
local dual_kawase_blur	= require("defrend.render.post_processors.dual_kawase_blur")
local dof				= require("defrend.render.post_processors.dof")
local fxaa				= require("defrend.render.post_processors.fxaa")

local M = {}

local processors = {
	outline,
	gamma,
	glow,
	bloom,
	kuwahara_blur,
	gaussian_blur,
	dual_kawase_blur,
	dof,
	fxaa,
}

local processor_settings = {
	[outline]			= settings.outline,
	[gamma]				= settings.gamma,
	[glow]				= settings.glow,
	[bloom]				= settings.bloom,
	[kuwahara_blur]		= settings.kuwahara_blur,
	[gaussian_blur]		= settings.gaussian_blur,
	[dual_kawase_blur]	= settings.dual_kawase_blur,
	[dof]				= settings.dof,
	[fxaa]				= settings.fxaa,
}

local active_list = {}

function M.init()
	for _, pp in ipairs(processors) do
		pp.init()
	end
	M.regenerate_active_list()
end

function M.regenerate_active_list()
	active_list = {}
	for _, pp in ipairs(processors) do
		if processor_settings[pp].enabled then
			table.insert(active_list, pp)
		end
	end
end

function M.update()
	for _, pp in ipairs(active_list) do
		render_targets.ping_pong()
		pp.update()
	end
end

M.master_list = processors

return M
