local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local entity_mod = require(ServerScriptService.Server.entity)
local coords_mod = require(ReplicatedStorage.Shared.coords)
type World = types.World

function compute_influences(world: World)
	for _, cell in world.cells do
		cell.influences = {}
	end

	local proxies = {}
	for _, entity in world:active_entities() do
		if entity.type == "proxy" and entity.status == "complete" then
			table.insert(proxies, entity)
		end
		local behavior = entity_mod.registry[entity.type]
		if behavior.influences then
			behavior.influences(entity, world)
		end
	end

	for _, entity in proxies do
		local cell = world:get_cell(entity.primary_coordinate)
		if next(cell.influences) == nil then
			continue
		end
		local neighbors = coords_mod.neighbors_leq(entity.primary_coordinate, 2)
		for _, coord in neighbors do
			local neighbor_cell = world:get_cell(coord)
			for influence in cell.influences do
				neighbor_cell.influences[influence] = true
			end
		end
	end
end

return {
	compute_influences = compute_influences,
}
