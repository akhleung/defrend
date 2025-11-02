local M = {}

local predicate_names = {
	"model", "decal", "skybox",
	"billboard", "sprite",
	"particle", "shadowless_particle",
	"point_light", "spot_light", "blob_shadow",
	"screen", "text", "gui", "debug_text",
}

function M.init()
	for _, name in ipairs(predicate_names) do
		M[name] = render.predicate({name})
	end
end

return M
