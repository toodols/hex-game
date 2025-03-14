local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local damage_mod = require(ServerScriptService.Server.damage)
local methods = require(script.methods)
local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)
local team = require(ReplicatedStorage.Shared.team)
local server_types = require(ServerScriptService.Server.types)

type Entity = types.Entity
type HexGrid = types.HexGrid
type Effect = types.Effect
type ActionState = server_types.ActionState
type EffectBehavior = {
	description: string?,
	desirability: "positive" | "negative" | "neutral" | nil,
	init: (grid: HexGrid, entity: Entity, effect: Effect) -> ()?,
	tick: (grid: HexGrid, action_state: ActionState, entity: Entity, effect: Effect) -> ()?,
	remove: (grid: HexGrid, entity: Entity, effect: Effect) -> ()?,
}

local effects: { [string]: EffectBehavior } = {}

-- Blocks effect.amount damage
effects.shield = {}

effects.regeneration = {
	description = "Gains +1 hitpoint every turn",
	desirability = "positive",
	init = function(grid: HexGrid, entity: Entity, effect: Effect) end,
	tick = function(grid: HexGrid, action_state: ActionState, entity: Entity, effect: Effect)
		damage_mod.damage_entity(grid, entity, {
			type = "healing",
			amount = 1,
		})
	end,
}

-- Todo: some negative debuff that comes with being infected
effects.infected = {
	desirability = "negative",
	init = function(grid: HexGrid, entity: Entity, effect: Effect) end,
	remove = function(grid: HexGrid, entity: Entity, effect: Effect) end,
	tick = function()
		-- todo: spread to other cells
	end,
}

return {
	effects = effects,
	get_effects = methods.get_effects,
	get_one_effect = methods.get_one_effect,
	add_exclusive_effect = methods.add_exclusive_effect,
	add_effect = methods.add_effect,
	purge_destroyed_effects = methods.purge_destroyed_effects,
}
