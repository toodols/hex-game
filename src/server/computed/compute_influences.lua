local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local server_entity_mod = require(ServerScriptService.Server.entity)
type HexGrid = types.HexGrid

function compute_influences(grid: HexGrid)
	for _, cell in grid.cells do
		cell.server_data.influences = {}
	end
	for _, entity in grid:active_entities() do
		local behavior = server_entity_mod.registry[entity.type]
		if behavior.influences then
			behavior.influences(entity, grid)
		end
	end
end

return {
	compute_influences = compute_influences,
}
