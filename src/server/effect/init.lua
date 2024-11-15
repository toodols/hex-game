local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
type Entity = types.Entity
type HexGrid = types.HexGrid
type Effect = types.Effect

function get_entity_effects(entity: Entity, effect_type: string): { Effect }
	local effects = {}
	for _, effect in entity.effects do
		if effect.type == effect_type then
			table.insert(effects, effect)
		end
	end
	return effects
end

function get_one_entity_effect(entity: Entity, effect_type: string): Effect?
	return get_entity_effects(entity, effect_type)[1]
end

local effects = {}
effects.shield = {
	tick = function(grid: HexGrid, entity: Entity, effect: Effect) end,
}
effects.infected = {
	tick = function(grid: HexGrid, entity: Entity, effect: Effect) end,
}

return { effects = effects, get_entity_effect = get_entity_effects, get_one_entity_effect = get_one_entity_effect }
