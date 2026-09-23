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

local master_list = {
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

local ordered_list = {} -- reflects the current ordering of the post-processors

local active_list = {} -- contains only the enabled post-processors in their current ordering

function M.init()
	for _, pp in ipairs(master_list) do
		pp.init()
		table.insert(ordered_list, pp)
	end
	M.regenerate_active_list()
end

function M.regenerate_active_list()
	active_list = {}
	for _, pp in ipairs(ordered_list) do
		if processor_settings[pp].enabled then
			table.insert(active_list, pp)
		end
	end
end

function M.move_up(i)
	if not (i > 1 and i <= #ordered_list) then
		return
	end
	ordered_list[i-1], ordered_list[i] = ordered_list[i], ordered_list[i-1]
end

function M.move_down(i)
	if not (i >= 1 and i < #ordered_list) then
		return
	end
	ordered_list[i], ordered_list[i+1] = ordered_list[i+1], ordered_list[i]
end

function M.update()
	for _, pp in ipairs(active_list) do
		render_targets.ping_pong()
		pp.update()
	end
end

M.master_list	= master_list
M.ordered_list	= ordered_list
M.active_list	= active_list

return M
