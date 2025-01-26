local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
type Entity = types.Entity
type Effect = types.Effect

function get_effects(entity: Entity, effect_type: string): { Effect }
	local effects = {}
	for _, effect in entity.effects do
		if effect.type == effect_type then
			table.insert(effects, effect)
		end
	end
	return effects
end

function get_one_effect(entity: Entity, effect_type: string): Effect?
	return get_effects(entity, effect_type)[1]
end

function add_exclusive_effect(entity: Entity, effect: Effect)
	local old_effect = get_one_effect(entity, effect.type)
	if old_effect == nil then
		table.insert(entity.effects, effect)
	else
		old_effect.duration = math.max(old_effect.duration, effect.duration)
	end
end

function add_effect(entity: Entity, effect: Effect)
	table.insert(entity.effects, effect)
end

return {
	get_effects = get_effects,
	get_one_effect = get_one_effect,
	add_exclusive_effect = add_exclusive_effect,
	add_effect = add_effect,
}
