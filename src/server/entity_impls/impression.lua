local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local coords = require(ReplicatedStorage.Shared.coords)
local team_mod = require(ReplicatedStorage.Shared.team)

local effect_mod = require(ServerScriptService.Server.effect)
local entity_mod = require(ServerScriptService.Server.entity)

type Entity = types.Entity
type World = types.World
type EntityEvent = types.EntityEvent

entity_mod.registry.impression = entity_mod.with_defaults {
	decayable = false,
	init = function(self: Entity, world: World) end,
	abilities = {
		activate = function(self: Entity, world: World)
			for _, cell in
				util.table_filter_map(coords.neighbors_leq(self.primary_coordinate, 1), function(coord)
					return world:get_cell(coord)
				end)
			do
				for entity_id in cell.entities do
					local affected_entity = world.entities[entity_id]
					if team_mod.is_allied(world, self.owner, affected_entity.owner) then
						continue
					end
					effect_mod.add_exclusive_effect(world, affected_entity, {
						type = "infected",
						duration = 1,
					})
				end
			end
		end,
	},
	on_event = function(self: Entity, world: World, event: EntityEvent)
		if event.entity_id == self.id and event.event_type == "destroy" and event.death_type == "killed" then
			entity_mod.registry[self.type].abilities.activate(self, world)
		end
	end,
}

return {}
