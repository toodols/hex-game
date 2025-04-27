local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local coords = require(ReplicatedStorage.Shared.coords)

local updates_mod = require(ServerScriptService.Server.updates)
local effect_mod = require(ServerScriptService.Server.effect)
local entity_mod = require(ServerScriptService.Server.entity)

type Entity = types.Entity
type World = types.World
type EntityEvent = types.EntityEvent

entity_mod.registry.solution = entity_mod.with_defaults {
	init = function(self: Entity, world: World)
		self.decayable = false
	end,
	abilities = {
		solution_use = function(self: Entity, world: World)
			local config = world.entity_configurations[self.type]
			for _, cell in
				util.table_filter_map(coords.neighbors_many_leq(self.coordinates, 1), function(coord)
					return world:get_cell(coord)
				end)
			do
				for entity_id in cell.entities do
					local affected_entity = world.entities[entity_id]

					-- it would be nice to use damage_mod for this but it doesn't support healing damage
					-- and this ignores layers
					affected_entity.health = math.max(
						affected_entity.max_health,
						affected_entity.health + config.abilities.solution_use.heal_amount
					)

					effect_mod.add_effect(affected_entity, {
						type = "shield",
						health = config.abilities.solution_use.shield_health,
						duration = config.abilities.solution_use.shield_duration,
					})

					updates_mod.add_update(world, {
						type = "entity_update",
						entity = affected_entity,
					})
				end
			end
		end,
	},
	on_event = function(self: Entity, world: World, event: EntityEvent)
		if event.event_type == "killed" then
			entity_mod.registry[self.type].abilities.solution_use(self, world)
		end
	end,
}

return {}
