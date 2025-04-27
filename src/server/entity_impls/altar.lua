local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local coords = require(ReplicatedStorage.Shared.coords)
local entity_mod = require(ServerScriptService.Server.entity)

type Entity = types.Entity
type World = types.World

entity_mod.registry.altar = entity_mod.with_defaults {
	autogenerates_vertex = true,
	on_completed = function(self: Entity, world: World) end,
	influences = function(self: Entity, world: World)
		local config = world.entity_configurations[self.type]
		local neighbors = coords.neighbors_leq(self.primary_coordinate, config.range)
		for _, coord in neighbors do
			local cell = world:get_cell(coord)
			if cell then
				cell.influences[self.id] = true
			end
		end
	end,
}

return {}
