local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)
local effect_mod = require(ServerScriptService.Server.effect)
local damage_mod = require(ServerScriptService.Server.damage)

local registry = effect_mod.registry

type World = types.World
type Entity = types.Entity
type Effect = types.Effect
type ActionState = server_types.ActionState

-- Blocks effect.amount damage
registry.shield = {}

registry.regeneration = {
	description = "Gains +1 hitpoint every turn",
	desirability = "positive",
	init = function(world: World, entity: Entity, effect: Effect) end,
	tick = function(world: World, action_state: ActionState, entity: Entity, effect: Effect)
		entity.health = math.min(entity.health + 1, entity.max_health)
	end,
}

-- Todo: some negative debuff that comes with being infected
registry.infected = {
	desirability = "negative",
	init = function(world: World, entity: Entity, effect: Effect) end,
	remove = function(world: World, entity: Entity, effect: Effect) end,
	tick = function()
		-- todo: spread to other cells
	end,
}

return {
	registry = registry,
}
