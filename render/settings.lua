local M = {
    resolution_x = 0,
    resolution_y = 0,
    shadow = {},
    ssao = {
        enabled = true,
        samples = 16,
        intensity = 1.875,
        scale = 2.5,
        bias = 0.3,
        radius = 1.75,
        max_distance = 1.75,
    },
    blur = {
        box = {
            enabled = true,
            samples = 1,
            radius = 2.0,
        },
        kuwahara = {
            enabled = true,
            samples = 1,
        },
    },
    fxaa = {
        enabled = true,
        strength = 12,
    },
}

local ssao = M.ssao
local ssao_params1 = vmath.vector4()
local ssao_params2 = vmath.vector4()
function M.ssao.set_uniforms(uniforms)
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
function M.blur.box.set_uniforms(uniforms)
    box_blur_params.x = M.resolution_x
    box_blur_params.y = M.resolution_y
    box_blur_params.z = box_blur.samples
    box_blur_params.w = box_blur.radius
    uniforms.params = box_blur_params
end

local kuwahara_blur = M.blur.kuwahara
local kuwahara_blur_params = vmath.vector4()
function M.blur.kuwahara.set_uniforms(uniforms)
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
