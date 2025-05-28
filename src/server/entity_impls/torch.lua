local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local coords_mod = require(ReplicatedStorage.Shared.coords)
local entity_mod = require(ServerScriptService.Server.entity)
local util = require(ReplicatedStorage.Shared.util)
local server_types = require(ServerScriptService.Server.types)

type Entity = types.Entity & {
	head_rotation: number,
}
type World = types.World
type EntityEvent = types.EntityEvent
type ActionState = server_types.ActionState

entity_mod.registry.torch = entity_mod.with_defaults {
	autogenerates_vertex = true,
	init = function(self: Entity, world: World)
		self.head_rotation = 0
	end,
	tick = function(self: Entity, world: World)
		if self.status == "complete" then
			self.head_rotation = (self.head_rotation + 1) % 6
			world:add_update {
				type = "entity_update",
				entity = self,
			}
		end
	end,
	illumination = function(self: Entity, world: World)
		return coords_mod.from_set(
			util.table_join(
				coords_mod.into_set(coords_mod.sector(self.primary_coordinate, self.head_rotation - 1, self.health + 1)),
				coords_mod.into_set(coords_mod.sector(self.primary_coordinate, self.head_rotation, self.health + 1))
			)
		)
	end,
}

return {}
