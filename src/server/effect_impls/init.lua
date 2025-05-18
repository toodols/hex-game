local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)
local effect_mod = require(ServerScriptService.Server.effect)
local world_mod = require(ReplicatedStorage.Shared.world)
local coords = require(ReplicatedStorage.Shared.coords)
local util = require(ReplicatedStorage.Shared.util)
local damage_mod = require(ServerScriptService.Server.damage)

local registry = effect_mod.registry

type World = types.World
type Entity = types.Entity
type Effect = types.Effect
type ActionState = server_types.ActionState

-- Blocks effect.amount damage
registry.shield = effect_mod.with_defaults {}

registry.regeneration = effect_mod.with_defaults {
	tick = function(world: World, action_state: ActionState, entity: Entity, effect: Effect)
		-- todo: replace this to use damage_mod
		entity.health = math.min(entity.health + 1, entity.max_health)
	end,
}

registry.infected = effect_mod.with_defaults {
	init = function(world: World, entity: Entity, effect: Effect)
		damage_mod.damage_entity(world, entity, { amount = 1, nonlethal = true })
		world:add_update {
			type = "entity_update",
			entity = entity,
		}
		effect_mod.add_effect(world, entity, {
			type = "infected_immune",
		})
	end,
	tick = function(world: World, action_state: ActionState, entity: Entity, effect: Effect)
		for _, cell in world_mod.into_cells(world, coords.neighbors_leq(entity.primary_coordinate, 1)) do
			for entity_id in cell.entities do
				local other_entity = world.entities[entity_id]
				if entity.owner ~= other_entity.owner then
					continue
				end

				if
					util.table_find_pred(other_entity.effects, function(other_effect)
						return other_effect.type == "infected_immune"
					end)
				then
					continue
				end
				effect_mod.add_effect(world, other_entity, {
					type = "infected",
					duration = 1,
				})
			end
		end
	end,
}

registry.infected_immune = effect_mod.with_defaults {}

-- being hidden will still impose a presence
registry.hidden = effect_mod.with_defaults {}

registry.inventory_lock = effect_mod.with_defaults {}

registry.taunt_immunity = effect_mod.with_defaults {}

registry.increase_damage = effect_mod.with_defaults {}

return {
	registry = registry,
}
