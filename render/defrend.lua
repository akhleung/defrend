local lighting = require "render.defrend-lighting"

local M = {}

local SHADOWMAP_RESOLUTION = 2048

function M.setup_clear_buffers(self)
    self.clear_color_buffers = {
        [graphics.BUFFER_TYPE_COLOR0_BIT] = vmath.vector4(
            sys.get_config_number("render.clear_color_red", 0),
            sys.get_config_number("render.clear_color_green", 0),
            sys.get_config_number("render.clear_color_blue", 0),
            sys.get_config_number("render.clear_color_alpha", 0)
        ),
        [graphics.BUFFER_TYPE_DEPTH_BIT] = 1,
        [graphics.BUFFER_TYPE_STENCIL_BIT] = 0
    }
    self.clear_shadow_buffers = {
        [graphics.BUFFER_TYPE_COLOR0_BIT] = vmath.vector4(
            sys.get_config_number("render.clear_color_red", 1),
            sys.get_config_number("render.clear_color_green", 1),
            sys.get_config_number("render.clear_color_blue", 1),
            sys.get_config_number("render.clear_color_alpha", 1)
        ),
        [graphics.BUFFER_TYPE_DEPTH_BIT] = 1,
        [graphics.BUFFER_TYPE_STENCIL_BIT] = 0
    }
end

function M.setup_render_targets(self)
    local color_params = {
        format = graphics.TEXTURE_FORMAT_RGBA,
        width  = render.get_window_width(),
        height = render.get_window_height(),
    }
    local position_params = {
        format = graphics.TEXTURE_FORMAT_RGBA16F,
        width  = render.get_window_width(),
        height = render.get_window_height(),
    }
    local depth_params = {
        format = graphics.TEXTURE_FORMAT_DEPTH,
        width  = render.get_window_width(),
        height = render.get_window_height(),
        -- flags  = render.TEXTURE_BIT
    }
    local ssao_params = {
        format = graphics.TEXTURE_FORMAT_R16F,
        width  = render.get_window_width(),
        height = render.get_window_height(),
    }
    local shadow_map_params = {
        format = graphics.TEXTURE_FORMAT_R16F,
        width = SHADOWMAP_RESOLUTION,
        height = SHADOWMAP_RESOLUTION,
    }
    local shadow_depth_params = {
        format = graphics.TEXTURE_FORMAT_DEPTH,
        width  = SHADOWMAP_RESOLUTION,
        height = SHADOWMAP_RESOLUTION,
        -- flags  = render.TEXTURE_BIT
    }

    self.shadow_map = render.render_target(
        "shadow_map",
        {
            [graphics.BUFFER_TYPE_COLOR0_BIT] = shadow_map_params,
            [graphics.BUFFER_TYPE_DEPTH_BIT] = shadow_depth_params,
        }
    )
    self.g_buffer = render.render_target(
        "g_buffer",
        {
            [graphics.BUFFER_TYPE_COLOR0_BIT] = color_params, -- diffuse color
            [graphics.BUFFER_TYPE_COLOR1_BIT] = position_params, -- positions
            [graphics.BUFFER_TYPE_COLOR2_BIT] = color_params, -- normals
            [graphics.BUFFER_TYPE_DEPTH_BIT]  = depth_params, -- depth
        }
    )
    self.ssao_target = render.render_target(
        "ssao_target",
        {
            [graphics.BUFFER_TYPE_COLOR0_BIT] = ssao_params, -- color
        }
    )
    self.post_target = render.render_target(
        "post_target",
        {
            [graphics.BUFFER_TYPE_COLOR0_BIT] = color_params, -- color
        }
    )
end

function M.setup_predicates(self)
    local arg = {"tile", "gui", "text", "particle", "model", "sprite", "transparent", "debug_text", "screen"}
    local predicates = {}
    for _, predicate_name in pairs(arg) do
        predicates[predicate_name] = render.predicate({predicate_name})
    end
    self.predicates = predicates
end

local identity = vmath.matrix4()
function M.setup_cameras(self)
    self.camera = {
        view = identity,
        proj = identity,
        viewproj = identity,
        moved = true,
    }
    local gui_proj = vmath.matrix4_orthographic(0, render.get_window_width(), 0, render.get_window_height(), -1, 1)
    self.camera_gui = {
        view = identity,
        proj = gui_proj,
        viewproj = gui_proj * identity,
    }
    local screen_proj = vmath.matrix4_orthographic(-.5, .5, -.5, .5, -1, 1)
    self.camera_screen = {
        view = identity,
        proj = screen_proj,
        viewproj = screen_proj * identity,
    }
end

M.setup_lights = lighting.setup_lights
M.refresh_shadows = lighting.refresh_shadows

return M
