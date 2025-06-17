local settings = require "render.settings"
local lighting = require "render.defrend-lighting"

local M = {}

local identity = vmath.matrix4()
local camera
function M.setup_cameras(self)
    self.camera = {
        view = identity,
        view_inv = identity,
        proj = identity,
        viewproj = identity,
        moved = true,

        near = 1,
        far = 1001,
        aspect = render.get_window_width() / render.get_window_height(),
        fov = 0.3927,
    }
    camera = self.camera

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
    M.camera = camera
end

function M.setup_clear_buffers(self)
    self.clear_color_buffers = {
        -- [graphics.BUFFER_TYPE_COLOR0_BIT] = vmath.vector4(
        --     sys.get_config_number("render.clear_color_red", 0),
        --     sys.get_config_number("render.clear_color_green", 0),
        --     sys.get_config_number("render.clear_color_blue", 0),
        --     sys.get_config_number("render.clear_color_alpha", 0)
        -- ),
        [graphics.BUFFER_TYPE_COLOR0_BIT] = vmath.vector4(0),
        [graphics.BUFFER_TYPE_DEPTH_BIT] = 1,
        [graphics.BUFFER_TYPE_STENCIL_BIT] = 0
    }
    self.clear_ssao_buffer = {
        [graphics.BUFFER_TYPE_COLOR0_BIT] = vmath.vector4(1, 1, 1, 1),
        [graphics.BUFFER_TYPE_DEPTH_BIT] = 1,
        [graphics.BUFFER_TYPE_STENCIL_BIT] = 0
    }
    self.clear_shadow_buffers = {
        [graphics.BUFFER_TYPE_COLOR0_BIT] = vmath.vector4(1, 1, 1, 1),
        [graphics.BUFFER_TYPE_DEPTH_BIT] = 1,
        [graphics.BUFFER_TYPE_STENCIL_BIT] = 0
    }
end

function M.setup_render_targets(self)
    local rgba_params = {
        format	= graphics.TEXTURE_FORMAT_RGBA,
        width	= render.get_window_width(),
        height	= render.get_window_height(),
    }
    local depth_params = {
        format	= graphics.TEXTURE_FORMAT_DEPTH,
        width	= render.get_window_width(),
        height	= render.get_window_height(),
        flags	= graphics.TEXTURE_USAGE_FLAG_SAMPLE, -- was render.TEXTURE_BIT
    }
    local shadow_depth_params = {
        format	= graphics.TEXTURE_FORMAT_DEPTH,
        width	= settings.shadow.atlas_resolution,
        height	= settings.shadow.atlas_resolution,
        flags	= graphics.TEXTURE_USAGE_FLAG_SAMPLE, -- was render.TEXTURE_BIT
    }

    self.shadow_map = render.render_target(
        "shadow_map",
        {
            [graphics.BUFFER_TYPE_DEPTH_BIT] = shadow_depth_params,
        }
    )
    self.g_buffer = render.render_target(
        "g_buffer",
        {
            [graphics.BUFFER_TYPE_COLOR0_BIT] = rgba_params, -- diffuse color & glow
            [graphics.BUFFER_TYPE_COLOR1_BIT] = rgba_params, -- normals & specular
            [graphics.BUFFER_TYPE_DEPTH_BIT]  = depth_params, -- depth
        }
    )
    self.l_buffer = render.render_target(
        "light_target",
        {
            [graphics.BUFFER_TYPE_COLOR0_BIT] = rgba_params, -- diffuse contribution
            [graphics.BUFFER_TYPE_COLOR1_BIT] = rgba_params, -- specular contribution
        }
    )
    self.post_source = render.render_target(
        "post_left",
        {
            [graphics.BUFFER_TYPE_COLOR0_BIT] = rgba_params, -- color
        }
    )
    self.post_target = render.render_target(
        "post_right",
        {
            [graphics.BUFFER_TYPE_COLOR0_BIT] = rgba_params, -- color
        }
    )
end

function M.setup_predicates(self)
    local arg = {
        "model", "sprite", "billboard", "blob_shadow", "decal", "point_light",
        "transparent", "tile", "particle", "screen",
        "gui", "text", "debug_text"
    }
    local predicates = {}
    for _, predicate_name in pairs(arg) do
        predicates[predicate_name] = render.predicate({predicate_name})
    end
    self.predicates = predicates
end

function M.screen_to_world(x, y)
    local inv_mtx = vmath.inv(camera.proj * camera.view)
    local w, h    = window.get_size()

    local near = inv_mtx * vmath.vector4(x / w * 2 - 1, y / h * 2 - 1, -1, 1)
    local far  = inv_mtx * vmath.vector4(x / w * 2 - 1, y / h * 2 - 1, 1, 1)
    near       = near / near.w
    far        = far / far.w
    near       = vmath.vector3(near.x, near.y, near.z)
    far        = vmath.vector3(far.x, far.y, far.z)

    return near, far
end

M.setup_lights = lighting.setup_lights
M.refresh_shadows_half_stable = lighting.refresh_shadows_half_stable
M.refresh_shadows_stable = lighting.refresh_shadows_stable
M.refresh_shadows_stable = lighting.refresh_shadows_stable2

return M
