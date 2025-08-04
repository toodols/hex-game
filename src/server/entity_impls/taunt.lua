local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local coords_mod = require(ReplicatedStorage.Shared.coords)
local world_mod = require(ReplicatedStorage.Shared.world)

local entity_mod = require(ServerScriptService.Server.entity)
local damage_mod = require(ServerScriptService.Server.damage)

type Entity = types.Entity
type World = types.World
type EntityEvent = types.EntityEvent

entity_mod.registry.taunt = entity_mod.with_defaults {
	autogenerates_vertex = true,
	on_completed = function(self: Entity, world: World) end,
	influences = function(self: Entity, world: World)
		local config = world.entity_configurations[self.type]
		local neighbors = world_mod.into_cells(world, coords_mod.neighbors_leq(self.primary_coordinate, config.range))
		for _, cell in neighbors do
			cell.influences[self.id] = true
		end
	end,
	on_event = function(self: Entity, world: World, event: EntityEvent)
		if event.entity_id == self.id and event.event_type == "destroy" and event.death_type == "killed" then
			local neighbors = coords_mod.neighbors_leq(self.primary_coordinate, 1)
			damage_mod.delayed_destruction(
				world,
				damage_mod.damage_cells(world, neighbors, {
					amount = 1,
					friendly_fire = true,
				})
			)
		end
	end,
}

return {}
