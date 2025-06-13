local M = {
    resolution_x = 0,
    resolution_y = 0,
    light = {
        fog_near = 800,
        fog_far = 1001,
        fog_color = vmath.vector4(0),
        ambient_color = vmath.vector4(0.7, 0.7, 0.7, 1.0),
        directional_color = vmath.vector4(1.0, 1.0, 0.92, 1.0),
        -- directional_color = vmath.vector4(0.23, 0.24, 0.25, 1.0),
        directional_to = vmath.normalize(vmath.vector4(0.5, -1.5, 1, 1)),
    },
    shadow = {
        stable = true,
        softness = 1,
        -- cascade = { 0.55, 0.15, 0.15, 0.15 },
        -- cascade = { 0.40, 0.20, 0.20, 0.20 },
        cascade = { 0.20, 0.10, 0.10, 0.20 },
        -- cascade = { 0.10, 0.20, 0.30, 0.40 },
        -- cascade = { 0.25, 0.25, 0.25, 0.25 },
        -- cascade = { 0.75 },
        biases = { 0.5, 0.75, 0.75, 1.2 },
        atlas_resolution = 4096,
        map_resolution = 0,
        map_dimension = 0,
        texel_size = 0,
        partitions = {},
        projections = {},
    },
    ssao = {
        enabled = true,
        blur = true,
        samples = 16,
        intensity = 1.5,
        bias_angle = 0.1,
        bias_dist = 0.5,
        min_distance = 1.0,
        max_distance = 4.0,
        attenuation = 1.0,
        radius = 2.0,

        kernel = {},
        noise = {},
    },
    outline = {
        enabled = false,
        -- outline
        depth_threshold		= 0.025,
        normal_threshold	= 0.5,
        normal_smoothing	= 0.25,
        -- thickness
        max_thickness	= 1.3,
        min_thickness	= 0.5,
        max_distance	= 75.0,
        min_distance	= 2.0,
        -- grazing prevention
        grazing_fresnel_power			= 5.0,
        grazing_angle_mask_power		= 1.0,
        grazing_angle_modulation_factor	= 50.0,
    },
    bloom = {
        enabled = false,
        threshold = 0.9,
        radius = 1,
        separation = 2,
        strength = 0.5,
    },
    box_blur = {
        radius = 1,
        separation = 1.0,
    },
    gaussian_blur = {
        enabled = false,
    },
    bilateral_blur = {
        enabled = false,
    },
    kuwahara_blur = {
        enabled = false,
        samples = 1,
    },
    dilate = {
        enabled = false,
        min_threshold = 0.1,
        max_threshold = 0.3,
        radius = 1,
        separation = 1,
    },
    dof = {
        enabled = false,
        focal_depth = 200,
        blur_start = 30,
        blur_full = 40,
    },
    gamma = {
        enabled = false,
        gamma = 2.2,
    },
    fxaa = {
        enabled = true,
        strength = 0,
    },
}

local light = M.light
local fog_params = vmath.vector4()
function M.light.set_uniforms(uniforms)
    uniforms.ambient_color = light.ambient_color
    uniforms.directional_color = light.directional_color
    uniforms.directional_to = light.directional_to
    uniforms.fog_color = light.fog_color
    fog_params.x = light.fog_near
    fog_params.y = light.fog_far
    uniforms.fog_params = fog_params
end

local shadow = M.shadow
function M.shadow.init(fov, aspect, near, far)
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
end

local shadow_params = vmath.vector4()
function M.shadow.set_uniforms(uniforms)
    shadow_params.x = shadow.map_resolution
    shadow_params.y = shadow.map_dimension
    shadow_params.z = shadow.softness
    shadow_params.w = #shadow.cascade
    uniforms.shadow_params = shadow_params
    uniforms.camera_partitions = shadow.partitions
end

local function ssao_init()
	math.randomseed(os.time())
	math.random()
	math.random()
	math.random()
	for i = 1, M.ssao.samples do
		local sample = vmath.normalize(
			vmath.vector4(
				math.random() * 2 - 1,
				math.random() * 2 - 1,
				math.random() * 2 - 1,
				1
			)
		)
		local scale = (i - 1) / M.ssao.samples
		scale = vmath.lerp(scale * scale, 0.1, 1.0)
		sample = sample * scale
		table.insert(M.ssao.kernel, sample)
	end
	for i = 1, M.ssao.samples do
		local noise = vmath.normalize(
			vmath.vector4(
				math.random() * 2 - 1,
				math.random() * 2 - 1,
				math.random() * 2 - 1,
				1
			)
		)
		table.insert(M.ssao.noise, noise)
	end
end

local ssao = M.ssao
local ssao_params1 = vmath.vector4()
local ssao_params2 = vmath.vector4()
ssao_init()
function M.ssao.set_uniforms(uniforms)
    ssao_params1.x = ssao.samples
    ssao_params1.y = ssao.intensity
    ssao_params1.z = ssao.bias_angle
    ssao_params1.w = ssao.bias_dist
    ssao_params2.x = ssao.min_distance
    ssao_params2.y = ssao.max_distance
    ssao_params2.z = ssao.attenuation
    ssao_params2.w = ssao.radius
    uniforms.params1 = ssao_params1
    uniforms.params2 = ssao_params2
end

local outline = M.outline
local outline_params1 = vmath.vector4()
local outline_params2 = vmath.vector4()
local outline_params3 = vmath.vector4()
function M.outline.set_uniforms(uniforms)
    outline_params1.x = M.resolution_x
    outline_params1.y = M.resolution_y
    outline_params1.z = outline.depth_threshold
    outline_params1.w = outline.normal_threshold

    outline_params2.x = outline.normal_smoothing
    outline_params2.y = outline.max_thickness
    outline_params2.z = outline.min_thickness
    outline_params2.w = outline.max_distance

    outline_params3.x = outline.min_distance
    outline_params3.y = outline.grazing_fresnel_power
    outline_params3.z = outline.grazing_angle_mask_power
    outline_params3.w = outline.grazing_angle_modulation_factor

    uniforms.params1 = outline_params1
    uniforms.params2 = outline_params2
end

local bloom = M.bloom
local bloom_params1 = vmath.vector4()
local bloom_params2 = vmath.vector4()
function M.bloom.set_uniforms(uniforms)
    bloom_params1.x = M.resolution_x
    bloom_params1.y = M.resolution_y
    bloom_params2.x = bloom.threshold
    bloom_params2.y = bloom.radius
    bloom_params2.z = bloom.separation
    bloom_params2.w = bloom.strength
    uniforms.params1 = bloom_params1
    uniforms.params2 = bloom_params2
end

local box_blur = M.box_blur
local box_blur_params = vmath.vector4()
function M.box_blur.set_uniforms(uniforms)
    box_blur_params.x = M.resolution_x
    box_blur_params.y = M.resolution_y
    box_blur_params.z = box_blur.radius
    box_blur_params.w = box_blur.separation
    uniforms.params = box_blur_params
end

local gaussian_blur_params = vmath.vector4()
function M.gaussian_blur.set_uniforms(uniforms)
    gaussian_blur_params.x = M.resolution_x
    gaussian_blur_params.y = M.resolution_y
    uniforms.params = gaussian_blur_params
end

local bilateral_blur_params = vmath.vector4()
function M.bilateral_blur.set_uniforms(uniforms)
    bilateral_blur_params.x = M.resolution_x
    bilateral_blur_params.y = M.resolution_y
    uniforms.params = bilateral_blur_params
end

local dilate = M.dilate
local dilate_params1 = vmath.vector4()
local dilate_params2 = vmath.vector4()
function M.dilate.set_uniforms(uniforms)
    dilate_params1.x = M.resolution_x
    dilate_params1.y = M.resolution_y
    dilate_params2.x = dilate.min_threshold
    dilate_params2.y = dilate.max_threshold
    dilate_params2.z = dilate.radius
    dilate_params2.w = dilate.separation
    uniforms.params1 = dilate_params1
    uniforms.params2 = dilate_params2
end

local dof = M.dof
local dof_params = vmath.vector4()
function M.dof.set_uniforms(uniforms)
    dof_params.x = dof.focal_depth
    dof_params.y = dof.blur_start
    dof_params.z = dof.blur_full
    uniforms.params = dof_params
end

local gamma = M.gamma
local gamma_params = vmath.vector4()
function M.gamma.set_uniforms(uniforms)
    gamma_params.x = gamma.gamma
    uniforms.params = gamma_params
end

local kuwahara_blur = M.kuwahara_blur
local kuwahara_blur_params = vmath.vector4()
function M.kuwahara_blur.set_uniforms(uniforms)
    kuwahara_blur_params.x = M.resolution_x
    kuwahara_blur_params.y = M.resolution_y
    kuwahara_blur_params.z = kuwahara_blur.samples
    uniforms.params = kuwahara_blur_params
end

local fxaa = M.fxaa
local fxaa_params = vmath.vector4()
function M.fxaa.set_uniforms(uniforms)
    fxaa_params.x = M.resolution_x
    fxaa_params.y = M.resolution_y
    fxaa_params.z = fxaa.strength
    uniforms.params = fxaa_params
end

return M
