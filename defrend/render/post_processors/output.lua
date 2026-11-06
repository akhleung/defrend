local settings          = require("defrend.render.settings").output
local render_targets    = require("defrend.render.resources.render_targets")
local predicates        = require("defrend.render.resources.predicates")

local M = {}

local options = {}

function M.init()
    ---@class Output_Constants
    ---@field tonemapping_params vector4
    ---@field adjustment_params vector4
    options.constants = render.constant_buffer() --[[@as Output_Constants]]
    local tonemapping_params = vmath.vector4()
    tonemapping_params.x = settings.mode
    tonemapping_params.y = settings.exposure
    tonemapping_params.z = settings.white
    tonemapping_params.w = 0
    if settings.debanding then
        tonemapping_params.w = 1
    end
    local adjustment_params = vmath.vector4()
    adjustment_params.x = settings.brightness
    adjustment_params.y = settings.contrast
    adjustment_params.z = settings.saturation
    adjustment_params.w = 0
    if settings.gamma then
        adjustment_params.w = 1
    end
    options.constants.tonemapping_params = tonemapping_params
    options.constants.adjustment_params = adjustment_params
end

function M.update()
    render.set_render_target(render.RENDER_TARGET_DEFAULT)
    render.enable_material("output_material")
    render.enable_texture("input_sampler", render_targets.get_post_source(), render_targets.POST_COLOR)
    render.draw(predicates.screen, options)
    render.disable_texture("input_sampler")
end

return M
