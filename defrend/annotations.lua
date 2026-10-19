---@meta

---@class Directional_Light
-- initial properties
---@field enabled boolean
---@field color vector4
---@field shadow_atlas render_target -- resource
---@field cascade vector4
---@field biases vector4
---@field partition_1_tint vector4
---@field partition_2_tint vector4
---@field partition_3_tint vector4
---@field partition_4_tint vector4
---@field cascade_transition_range number
---@field light_frustum_z_padding number
---@field pcf_samples number
---@field poisson_disc_samples number
---@field poisson_scale number
---@field hash_factor number
---@field hash_scale number
---@field soft_penumbras boolean
-- computed properties
---@field url url
---@field id userdata
---@field direction vector3
---@field render_target string | number | userdata -- render target handle used by render script
---@field attachment number -- sampler handle used by render script
---@field atlas_resolution number
---@field atlas_dimension number
---@field map_resolution number
---@field partitions vector4[]
---@field projections matrix4[]
---@field light_frustums table<string, number>[]
---@field mtx_views matrix4[]
---@field mtx_projs matrix4[]
---@field mtx_frustums matrix4[]
---@field uniforms Directional_Light_Uniforms
-- provide this method so that the render script can call it with up-to-date camera matrices
---@field update fun(self: Directional_Light, cam_view: matrix4, cam_view_inv: matrix4)

---@class Directional_Light_Uniforms
---@field mtx_view matrix4
---@field frustum_corner vector4
---@field frustum_terms vector4
---@field color vector4
---@field direction vector4
---@field shadow_params1 vector4
---@field shadow_params2 vector4
---@field shadow_params3 vector4
---@field partitions vector4[]
---@field shadow_tints vector4[]
---@field mtx_lights matrix4[]

---@class Point_Light
-- initial properties
-- computed properties

---@class Point_Light_Uniforms

---@class Spot_Light
-- initial properties
-- computed properties

---@class Spot_Light_Uniforms

return {}
