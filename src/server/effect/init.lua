local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local damage_mod = require(ServerScriptService.Server.damage)
local methods = require(script.methods)
local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)
local team = require(ReplicatedStorage.Shared.team)

type Entity = types.Entity
type HexGrid = types.HexGrid
type Effect = types.Effect

local effects = {}

-- Blocks effect.amount damage
effects.shield = {}

-- Deals 1 nonlethal damage, spreads to friendly entities on neighboring cells the next turn
effects.infected = {
	init = function(grid: HexGrid, entity: Entity, effect: Effect)
		damage_mod.damage_entity(grid, entity, {
			amount = 1,
			nonlethal = true,
		})
	end,
	remove = function(grid: HexGrid, entity: Entity, effect: Effect)
		methods.add_exclusive_effect(entity, { type = "infected_immune", duration = 5 })
		for _, cell in hex_grid_mod.neighbors_many_leq(entity.coordinates, 1) do
			for entity_id in cell.entities do
				local other = grid.entities[entity_id]
				if
					team.is_allied(grid, other.owner, entity.owner)
					and methods.get_one_effect(other, "infected_immune") == nil
				then
					methods.add_exclusive_effect(other, { type = "infected", duration = 1 })
				end
			end
		end
	end,
}

-- This entity is immune to `infected`
effects.infected_immune = {}

return {
	effects = effects,
	get_effects = methods.get_effects,
	get_one_effect = methods.get_one_effect,
	add_exclusive_effect = methods.add_exclusive_effect,
	add_effect = methods.add_effect,
}
