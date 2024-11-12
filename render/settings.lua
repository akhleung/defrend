local M = {
    resolution_x = 0,
    resolution_y = 0,
    shadow = {
        cascade = { 0.70, 0.10, 0.10, 0.10 },
        map_resolution = 2048,
        map_dimension = 0,
        buffer_resolution = 0,
        texel_size = 0,
        partitions = {},
        projections = {},
    },
    ssao = {
        enabled = true,
        samples = 16,
        intensity = 2.0,
        scale = 2.5,
        bias = 0.45,
        radius = 1.75,
        max_distance = 1.75,
    },
    blur = {
        box = {
            enabled = false,
            samples = 1,
            radius = 2.0,
        },
        kuwahara = {
            enabled = true,
            samples = 1,
        },
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

local shadow = M.shadow
function shadow.init(fov, aspect, near, far)
    shadow.map_dimension = math.ceil(math.sqrt(#shadow.cascade))
    shadow.buffer_resolution = shadow.map_resolution * shadow.map_dimension
    shadow.texel_size = 1 / shadow.map_resolution
    local total_range = far - near
    for i = 1, #shadow.cascade do
        far = near + total_range * shadow.cascade[i]
        local y_offset = math.floor((i - 1) / shadow.map_dimension) * shadow.map_resolution
        local x_offset = ((i - 1) % shadow.map_dimension) * shadow.map_resolution
        shadow.partitions[i] = vmath.vector4(x_offset, y_offset, far, #shadow.cascade)
        shadow.projections[i] = vmath.matrix4_perspective(fov, aspect, near, far)
        near = far
    end
end

local shadow_params = vmath.vector4()
function shadow.set_uniforms(uniforms)
    shadow_params.x = shadow.map_resolution
    shadow_params.y = shadow.buffer_resolution
    shadow_params.z = shadow.map_dimension
    shadow_params.w = shadow.texel_size
    uniforms.shadow_params = shadow_params
    uniforms.camera_partitions = shadow.partitions
    uniforms.camera_projections = shadow.projections
end

local ssao = M.ssao
local ssao_params1 = vmath.vector4()
local ssao_params2 = vmath.vector4()
function ssao.set_uniforms(uniforms)
    ssao_params1.x = ssao.samples
    ssao_params1.y = ssao.intensity
    ssao_params1.z = ssao.scale
    ssao_params1.w = ssao.bias
    ssao_params2.x = ssao.radius
    ssao_params2.y = ssao.max_distance
    uniforms.params1 = ssao_params1
    uniforms.params2 = ssao_params2
end

local box_blur = M.blur.box
local box_blur_params = vmath.vector4()
function box_blur.set_uniforms(uniforms)
    box_blur_params.x = M.resolution_x
    box_blur_params.y = M.resolution_y
    box_blur_params.z = box_blur.samples
    box_blur_params.w = box_blur.radius
    uniforms.params = box_blur_params
end

local kuwahara_blur = M.blur.kuwahara
local kuwahara_blur_params = vmath.vector4()
function kuwahara_blur.set_uniforms(uniforms)
    kuwahara_blur_params.x = M.resolution_x
    kuwahara_blur_params.y = M.resolution_y
    kuwahara_blur_params.z = kuwahara_blur.samples
    uniforms.params = kuwahara_blur_params
end

local fxaa = M.fxaa
local fxaa_params = vmath.vector4()
function fxaa.set_uniforms(uniforms)
    fxaa_params.x = M.resolution_x
    fxaa_params.y = M.resolution_y
    fxaa_params.z = fxaa.strength
    uniforms.params = fxaa_params
end

return M
