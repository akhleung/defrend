---@diagnostic disable: inject-field
local settings = require "defrend.render.settings"

local M = {
	geometry			= { uniforms = render.constant_buffer() },
	light				= {},
	shadow				= {},
	light_and_shadow	= { uniforms = render.constant_buffer() },
	ssao				= { uniforms = render.constant_buffer() },
	outline				= { uniforms = render.constant_buffer() },
	glow				= { uniforms = render.constant_buffer() },
	bloom				= { uniforms = render.constant_buffer() },
	box_blur			= { uniforms = render.constant_buffer() },
	gaussian_blur		= { uniforms = render.constant_buffer() },
	dilate				= { uniforms = render.constant_buffer() },
	dof					= { uniforms = render.constant_buffer() },
	gamma				= { uniforms = render.constant_buffer() },
	kuwahara_blur		= { uniforms = render.constant_buffer() },
	fxaa				= { uniforms = render.constant_buffer() },
}

local light = settings.light
local fog_params = vmath.vector4()
local light_vol_attn = vmath.vector4()
function M.light.init()
	fog_params.x = light.fog_near
	fog_params.y = light.fog_far
	M.light_and_shadow.uniforms.fog_params			= fog_params
	M.light_and_shadow.uniforms.fog_color			= light.fog_color
	M.light_and_shadow.uniforms.ambient_color		= light.ambient_color
	M.light_and_shadow.uniforms.directional_color	= light.directional_color
	M.light_and_shadow.uniforms.directional_to		= light.directional_to

	light_vol_attn.x = light.point_light_attenuation
	light_vol_attn.y = light.spot_light_range_attenuation
	light_vol_attn.z = light.spot_light_spread_attenuation
	M.geometry.uniforms.light_vol_attn = light_vol_attn
end

local shadow = settings.shadow
local shadow_params1 = vmath.vector4()
local shadow_params2 = vmath.vector4()
function M.shadow.init(fov, aspect, near, far)
	shadow.partitions = {}
	shadow.projections = {}
	shadow.map_dimension = math.ceil(math.sqrt(#shadow.cascade))
	shadow.map_resolution = shadow.atlas_resolution / shadow.map_dimension
	shadow.texel_size = 1 / shadow.map_resolution
	local total_range = far - near
	for i = 1, #shadow.cascade do
		far = near + total_range * shadow.cascade[i]
		local y_offset = math.floor((i - 1) / shadow.map_dimension) / shadow.map_dimension -- * shadow.map_resolution
		local x_offset = ((i - 1) % shadow.map_dimension) / shadow.map_dimension -- * shadow.map_resolution
		shadow.partitions[i] = vmath.vector4(x_offset, y_offset, far, shadow.biases[i])
		shadow.projections[i] = vmath.matrix4_perspective(fov, aspect, near, far)
		near = far
	end
	shadow_params1.x = shadow.map_resolution
	shadow_params1.y = shadow.map_dimension
	shadow_params1.z = shadow.poisson_scale
	shadow_params1.w = shadow.poisson_samples
	shadow_params2.x = shadow.pcf_samples
	shadow_params2.y = 0
	if shadow.soft_penumbras then
		shadow_params2.y = 1
	end
	shadow_params2.z = #shadow.cascade
	shadow_params2.w = shadow.transition_range
	M.light_and_shadow.uniforms.shadow_params1		= shadow_params1
	M.light_and_shadow.uniforms.shadow_params2		= shadow_params2
	M.light_and_shadow.uniforms.camera_partitions	= shadow.partitions
	M.light_and_shadow.uniforms.mtx_lights			= {}
	M.light_and_shadow.uniforms.shadow_colors		= {
		vmath.vector4(1, 0, 0, 1),
		vmath.vector4(0, 1, 0, 1),
		vmath.vector4(0, 0, 1, 1),
		vmath.vector4(0, 0, 1, 1),
	}
end

local ssao = settings.ssao
local ssao_params1	= vmath.vector4()
local ssao_params2	= vmath.vector4()
local ssao_params	= vmath.vector4() -- for sending the viewport scale to the lighting shader
function M.ssao.init()
	ssao_params1.x = ssao.samples
	ssao_params1.y = ssao.intensity
	ssao_params1.z = ssao.bias_angle
	ssao_params1.w = ssao.bias_dist
	ssao_params2.x = ssao.min_distance
	ssao_params2.y = ssao.max_distance
	ssao_params2.z = ssao.attenuation
	ssao_params2.w = ssao.radius
	M.ssao.uniforms.params1 = ssao_params1
	M.ssao.uniforms.params2 = ssao_params2

	-- the lighting phase needs to know the ssao viewport scale
	ssao_params.x = settings.ssao.scale
	M.light_and_shadow.uniforms.ssao_params = ssao_params
end

local outline = settings.outline
local outline_params1 = vmath.vector4()
local outline_params2 = vmath.vector4()
local outline_params3 = vmath.vector4()
function M.outline.init()
	outline_params1.x = outline.depth_threshold
	outline_params1.y = outline.normal_threshold
	outline_params1.z = outline.normal_smoothing

	outline_params2.x = outline.max_thickness
	outline_params2.y = outline.min_thickness
	outline_params2.z = outline.max_distance
	outline_params2.w = outline.min_distance

	outline_params3.x = outline.grazing_fresnel_power
	outline_params3.y = outline.grazing_angle_mask_power
	outline_params3.z = outline.grazing_angle_modulation_factor

	M.outline.uniforms.params1			= outline_params1
	M.outline.uniforms.params2			= outline_params2
	M.outline.uniforms.params3			= outline_params3
	M.outline.uniforms.outline_color	= outline.outline_color
end

local glow = settings.glow
local glow_params = vmath.vector4()
function M.glow.init()
	glow_params.x = glow.radius
	glow_params.y = glow.separation
	M.glow.uniforms.params = glow_params
end

local bloom = settings.bloom
local bloom_params = vmath.vector4()
function M.bloom.init()
	bloom_params.x = bloom.threshold
	bloom_params.y = bloom.radius
	bloom_params.z = bloom.separation
	bloom_params.w = bloom.strength
	M.bloom.uniforms.params = bloom_params
end

local box_blur = settings.box_blur
local box_blur_params = vmath.vector4()
function M.box_blur.init()
	box_blur_params.x = box_blur.radius
	box_blur_params.y = box_blur.separation
	M.box_blur.uniforms.params = box_blur_params
end

function M.gaussian_blur.init()
	-- just leave this stub here in case we need it someday
end

local dilate = settings.dilate
local dilate_params = vmath.vector4()
function M.dilate.init()
	dilate_params.x = dilate.min_threshold
	dilate_params.y = dilate.max_threshold
	dilate_params.z = dilate.radius
	dilate_params.w = dilate.separation
	M.dilate.uniforms.params = dilate_params
end

local dof = settings.dof
local dof_params = vmath.vector4()
function M.dof.init()
	dof_params.x = dof.focal_depth
	dof_params.y = dof.blur_start
	dof_params.z = dof.blur_full
	M.dof.uniforms.params = dof_params
end

local gamma = settings.gamma
local gamma_params = vmath.vector4()
function M.gamma.init()
	gamma_params.x = gamma.gamma
	M.gamma.uniforms.params = gamma_params
end

local kuwahara_blur = settings.kuwahara_blur
local kuwahara_blur_params = vmath.vector4()
function M.kuwahara_blur.init()
	kuwahara_blur_params.x = kuwahara_blur.samples
	M.kuwahara_blur.uniforms.params = kuwahara_blur_params
end

local fxaa = settings.fxaa
local fxaa_params = vmath.vector4()
function M.fxaa.init()
	fxaa_params.x = fxaa.iterations
	M.fxaa.uniforms.params = fxaa_params
end

return M
