local M = {}

local predicate_names = {
	"model", "sprite", "billboard", "decal", "skybox",
	"blob_shadow", "point_light", "spot_light",
	"screen", "text", "gui", "debug_text",
}

function M.init()
	for _, name in ipairs(predicate_names) do
		M[name] = render.predicate({name})
	end
end

return M
