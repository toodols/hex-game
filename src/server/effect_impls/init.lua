local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)
local effect_mod = require(ServerScriptService.Server.effect)

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

-- Todo: some negative debuff that comes with being infected
registry.infected = effect_mod.with_defaults {
	tick = function()
		-- todo: spread to other cells
	end,
}

-- being hidden will still impose a presence
registry.hidden = effect_mod.with_defaults {}

registry.inventory_lock = effect_mod.with_defaults {}

registry.taunt_immunity = effect_mod.with_defaults {}

registry.increase_damage = effect_mod.with_defaults {}

return {
	registry = registry,
}
