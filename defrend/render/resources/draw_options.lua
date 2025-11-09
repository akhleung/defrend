local settings	= require "defrend.render.settings"
local uniforms	= require "defrend.render.uniforms"

local M = {
	shadow_options			= {},
	geometry_options		= {},
	lighting_options		= {},
	copy_options			= {},
	ssao_options			= {},
	outline_options			= {},
	glow_options			= {},
	bloom_options			= {},
	gaussian_blur_options	= {},
	dual_kawase_options		= {},
	dilate_options			= {},
	kuwahara_blur_options	= {},
	gamma_options			= {},
	dof_options				= {},
	fxaa_options			= {},
}

function M.init()
	M.geometry_options.sort_order		= render.SORT_FRONT_TO_BACK
	M.geometry_options.constants		= uniforms.geometry.uniforms
	M.shadow_options.frustum_planes		= render.FRUSTUM_PLANES_ALL
	M.shadow_options.sort_order			= render.SORT_FRONT_TO_BACK
	M.shadow_options.constants			= render.constant_buffer()
	M.shadow_options.constants.bias		= vmath.vector4(settings.shadow.biases[1]) ---@diagnostic disable-line: inject-field

	M.lighting_options.constants		= uniforms.light_and_shadow.uniforms
	M.copy_options.constants			= render.constant_buffer()
	M.copy_options.constants.params		= vmath.vector4(1, 0, 0, 0) ---@diagnostic disable-line: inject-field
	M.ssao_options.constants			= uniforms.ssao.uniforms
	M.outline_options.constants			= uniforms.outline.uniforms
	M.glow_options.constants			= uniforms.glow.uniforms
	M.bloom_options.constants			= uniforms.bloom.uniforms
	M.gaussian_blur_options.constants	= uniforms.gaussian_blur.uniforms
	M.dual_kawase_options.constants		= uniforms.dual_kawase_blur.uniforms
	M.dilate_options.constants			= uniforms.dilate.uniforms
	M.kuwahara_blur_options.constants	= uniforms.kuwahara_blur.uniforms
	M.gamma_options.constants			= uniforms.gamma.uniforms
	M.dof_options.constants				= uniforms.dof.uniforms
	M.fxaa_options.constants			= uniforms.fxaa.uniforms
end



return M
