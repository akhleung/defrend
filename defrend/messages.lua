local M = {
	ENABLE = hash("enable"),
	DISABLE = hash("disable"),
	REFRESH = hash("refresh"),
	UNIFORMS = hash("uniforms"),
	WINDOW_RESIZED = hash("window_resized"),
	SET_VIEW_PROJ = hash("set_view_projection"),
	RESIZE_SHADOW_MAP = hash("resize_shadow_map"),
	RESIZE_POINT_LIGHT_SHADOW_MAP = hash("resize_point_light_shadow_map"),
	UPDATE_POINT_LIGHT = hash("update_point_light"),
	REMOVE_POINT_LIGHT = hash("remove_point_light"),
	UPDATE_SPOT_LIGHT = hash("update_spot_light"),
	REMOVE_SPOT_LIGHT = hash("remove_spot_light"),
}

return M