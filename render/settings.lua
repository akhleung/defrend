local M = {
    resolution_x = 0,
    resolution_y = 0,
    light = {
        fog_near = 40,
        fog_far = 60,
        fog_color = vmath.vector4(1),
        ambient_color = vmath.vector4(0.7, 0.7, 0.7, 1.0),
        directional_color = vmath.vector4(.95, .95, .95, 1.0),
        directional_to = vmath.normalize(vmath.vector4(0.5, -1.5, 1, 1)),
    },
    shadow = {
        bias = 0.5,
        cascade = { 0.55, 0.15, 0.15, 0.15 },
        map_resolution = 2048,
        map_dimension = 0,
        buffer_resolution = 0,
        texel_size = 0,
        partitions = {},
        projections = {},
    },
    ssao = {
        enabled = true,
        blur = false,
        samples = 16,
        intensity = 1.5,
        bias = 0.1,
        radius = 2.0,
        max_distance = 2.0,
        attenuation = 0.0,
    },
    box_blur = {
        samples = 1,
        radius = 2.0,
    },
    kuwahara_blur = {
        enabled = true,
        samples = 1,
    },
    dof = {},
    bloom = {},
    gamma = {
        enabled = false,
        gamma = 2.2,
    },
    fxaa = {
        enabled = true,
        strength = 12,
    },
}

local light = M.light
local light_params = vmath.vector4()
function M.light.set_uniforms(uniforms)
    uniforms.ambient_color = light.ambient_color
    uniforms.directional_color = light.directional_color
    uniforms.directional_to = light.directional_to
    uniforms.fog_color = light.fog_color
    light_params.x = light.fog_near
    light_params.y = light.fog_far
    uniforms.light_params = light_params
end

local shadow = M.shadow
function M.shadow.init(fov, aspect, near, far)
    shadow.map_dimension = math.ceil(math.sqrt(#shadow.cascade))
    shadow.buffer_resolution = shadow.map_resolution * shadow.map_dimension
    shadow.texel_size = 1 / shadow.map_resolution
    local total_range = far - near
    for i = 1, #shadow.cascade do
        far = near + total_range * shadow.cascade[i]
        local y_offset = math.floor((i - 1) / shadow.map_dimension) / shadow.map_dimension -- * shadow.map_resolution
        local x_offset = ((i - 1) % shadow.map_dimension) / shadow.map_dimension -- * shadow.map_resolution
        shadow.partitions[i] = vmath.vector4(x_offset, y_offset, far, #shadow.cascade)
        shadow.projections[i] = vmath.matrix4_perspective(fov, aspect, near, far)
        near = far
    end
end

local shadow_params = vmath.vector4()
function M.shadow.set_uniforms(uniforms)
    shadow_params.x = shadow.map_resolution
    shadow_params.y = shadow.map_dimension
    shadow_params.z = shadow.texel_size
    shadow_params.w = shadow.bias
    uniforms.shadow_params = shadow_params
    uniforms.camera_partitions = shadow.partitions
end

local ssao = M.ssao
local ssao_params1 = vmath.vector4()
local ssao_params2 = vmath.vector4()
function M.ssao.set_uniforms(uniforms)
    ssao_params1.x = ssao.samples
    ssao_params1.y = ssao.intensity
    ssao_params1.z = ssao.bias
    ssao_params1.w = ssao.radius
    ssao_params2.x = ssao.max_distance
    ssao_params2.y = ssao.attenuation
    uniforms.params1 = ssao_params1
    uniforms.params2 = ssao_params2
end

local box_blur = M.box_blur
local box_blur_params = vmath.vector4()
function M.box_blur.set_uniforms(uniforms)
    box_blur_params.x = M.resolution_x
    box_blur_params.y = M.resolution_y
    box_blur_params.z = box_blur.samples
    box_blur_params.w = box_blur.radius
    uniforms.params = box_blur_params
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
