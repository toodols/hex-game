local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local entity_mod = require(ServerScriptService.Server.entity)
type World = types.World

function compute_influences(world: World)
	for _, cell in world.cells do
		cell.server_data.influences = {}
	end
	for _, entity in world:active_entities() do
		local behavior = entity_mod.registry[entity.type]
		if behavior.influences then
			behavior.influences(entity, world)
		end
	end
end

return {
	compute_influences = compute_influences,
}
