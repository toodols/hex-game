local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)

type World = types.World
type Entity = types.Entity
type Effect = types.Effect
type ActionState = server_types.ActionState
type EffectBehavior = {
	description: string?,
	desirability: "positive" | "negative" | "neutral" | nil,
	init: (world: World, entity: Entity, effect: Effect) -> ()?,
	tick: (world: World, action_state: ActionState, entity: Entity, effect: Effect) -> ()?,
	remove: (world: World, entity: Entity, effect: Effect) -> ()?,
}
local registry: { [string]: EffectBehavior } = {}

local noop = function() end
function with_defaults(effect: EffectBehavior): EffectBehavior
	return {
		description = effect.description,
		desirability = effect.desirability or "neutral",
		init = effect.init or noop,
		tick = effect.tick or noop,
		remove = effect.remove or noop,
	}
end

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

function add_exclusive_effect(world: World, entity: Entity, effect: Effect): Effect
	local effect_behavior = registry[effect.type]
	local old_effect = get_one_effect(entity, effect.type)
	if old_effect == nil then
		table.insert(entity.effects, effect)
		effect_behavior.init(world, entity, effect)
		return effect
	else
		if effect.duration then
			old_effect.duration = math.max(old_effect.duration, effect.duration)
		else
			old_effect.duration = nil
		end
		return old_effect
	end
end

function add_effect(world: World, entity: Entity, effect: Effect): Effect
	local effect_behavior = registry[effect.type]
	table.insert(entity.effects, effect)
	effect_behavior.init(world, entity, effect)
	return effect
end

function purge_destroyed_effects(entity: Entity)
	local new_effects = {}
	for _, effect in entity.effects do
		if not effect.is_destroyed then
			table.insert(new_effects, effect)
		end
	end
	entity.effects = new_effects
end

function destroy_effect(world: World, entity: Entity, effect: Effect)
	local effect_behavior = registry[effect.type]
	effect_behavior.remove(world, entity, effect)
	effect.is_destroyed = true
end

return {
	get_effects = get_effects,
	get_one_effect = get_one_effect,
	add_exclusive_effect = add_exclusive_effect,
	add_effect = add_effect,
	purge_destroyed_effects = purge_destroyed_effects,
	destroy_effect = destroy_effect,
	registry = registry,
	with_defaults = with_defaults,
}
