local ServerScriptService = game:GetService "ServerScriptService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ServerScriptService.Server.entity)
local types = require(ReplicatedStorage.Shared.types)
local coords = require(ReplicatedStorage.Shared.coords)
type Entity = types.Entity
type World = types.World

entity_mod.registry.scout = entity_mod.with_defaults {
	autogenerates_vertex = true,
	illumination = function(self: Entity, world: World)
		return coords.neighbors_leq(self.primary_coordinate, 3)
	end,
}

return {}
