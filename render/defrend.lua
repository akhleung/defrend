local lighting = require "render.defrend-lighting"

local M = {}

local SHADOW_MAP_RESOLUTION = 2048

local identity = vmath.matrix4()
function M.setup_cameras(self)
    self.camera = {
        view = identity,
        proj = identity,
        viewproj = identity,
        moved = true,

        near = 1,
        far = 120,
        aspect = render.get_window_width() / render.get_window_height(),
        fov = 0.7854,
    }

    -- setup camera frustum partitions and shadow map viewports for cascaded shadow mapping
    -- local ranges = { 0.05, 0.10, 0.30, 0.55 }
    local range_sizes = { 0.1, 0.2, 0.3, 0.4 }
    local shadow_map_dim = math.ceil(math.sqrt(#range_sizes)) -- 2 in this case, for a 2x2 shadow map
    local near, far = self.camera.near, self.camera.far
    local total_range = far - near
    local partitions = {}
    local projections = {}
    local transforms = {}
    for i = 1, #range_sizes do
        far = near + total_range * range_sizes[i]
        local y_offset = math.floor((i - 1) / shadow_map_dim) * SHADOW_MAP_RESOLUTION
        local x_offset = ((i - 1) % shadow_map_dim) * SHADOW_MAP_RESOLUTION
        partitions[i] = vmath.vector4(x_offset, y_offset, near, 0)
        projections[i] = vmath.matrix4_perspective(self.camera.fov, self.camera.aspect, near, far)
        transforms[i] = {}
        near = far
    end
    self.camera.partitions = partitions -- to be passed to the lighting shader
    self.camera.projections = projections -- to be used for calculating the light projections for shadow rendering
    self.light_transforms = transforms -- to be used for storing the light views and projections for shadow rendering

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

    self.SHADOW_MAP_RESOLUTION = SHADOW_MAP_RESOLUTION
    self.SHADOW_BUFFER_RESOLUTION = SHADOW_MAP_RESOLUTION * shadow_map_dim
end

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
        [graphics.BUFFER_TYPE_COLOR0_BIT] = vmath.vector4(1, 1, 1, 1),
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
        width = self.SHADOW_BUFFER_RESOLUTION,
        height = self.SHADOW_BUFFER_RESOLUTION,
    }
    local shadow_depth_params = {
        format = graphics.TEXTURE_FORMAT_DEPTH,
        width  = self.SHADOW_BUFFER_RESOLUTION,
        height = self.SHADOW_BUFFER_RESOLUTION,
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

M.setup_lights = lighting.setup_lights
M.refresh_shadows = lighting.refresh_shadows

return M
