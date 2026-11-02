local M = {}

function M.init()
	M.model					= render.predicate({"model"})
	M.billboard				= render.predicate({"billboard"})
	M.sprite				= render.predicate({"sprite"})
	M.particle				= render.predicate({"particle"})
	M.shadowless_particle	= render.predicate({"particle", "shadowless"})
	M.decal					= render.predicate({"decal"})
	M.skybox				= render.predicate({"skybox"})
	M.point_light			= render.predicate({"point_light"})
	M.spot_light			= render.predicate({"spot_light"})
	M.screen				= render.predicate({"screen"})
	M.text					= render.predicate({"text"})
	M.gui					= render.predicate({"gui"})
	M.debug_text			= render.predicate({"debug_text"})
end

return M
