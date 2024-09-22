local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)

type Entity = types.Entity
type EntityId = types.EntityId
type Item = types.Item
type Decision = types.Decision
type HexGrid = types.HexGrid
type TeamId = types.TeamId
type EffectiveDamage = types.EffectiveDamage
type ResearchId = types.ResearchId

export type EntityEvent = {
	type: "dealt_damage",
	damage: EffectiveDamage,
	entity_id: EntityId,
} | {
	type: "took_damage",
	damage: EffectiveDamage,
	entity_id: EntityId,
} | {
	type: "consumed_items",
	items: { [Item]: number },
	entity_id: EntityId,
} | {
	type: "produced_items",
	items: { [Item]: number },
	entity_id: EntityId,
} | {
	type: "status_changed",
	entity_id: EntityId,
} | {
	type: "removed",
	entity_id: EntityId,
} | {
	type: "created",
	entity_id: EntityId,
} | {
	type: "update",
	entity_id: EntityId,
} | {
	type: "research_completed",
	entity_id: EntityId,
	research_id: ResearchId,
}

export type EntityAction =
	-- attempt to fill as much of the blueprint as possible from inventories and overflow
	-- if enough items are fulfilled, the blueprint promotes to scaffold. if the build time is 0, it automatically promotes to complete
	{
		type: "try_promote_blueprint",
		entity_id: EntityId,
	}
	-- advances scaffold by 1 turn
	-- if build time is 0, it is promoted to complete
	| {
		type: "try_promote_scaffold",
		entity_id: EntityId,
	}
	| {
		type: "exchange",
		input_items: { [Item]: number }?,
		input_power: number?,
		output_items: { Item }?,
		output_power: number?,
		on_success: (grid: HexGrid, action_state: ActionState, system: System) -> (),
	}
	| Decision

export type DamageResult = {
	-- whether to propagate damage to the next layer(s)
	propagate: boolean,
	-- how much damage was applied
	effective: number,
}
export type ActionState = {
	queue: { EntityAction },
	-- read as: entity is dirty for team in dirty_entities[entity.id][team.id]
	dirty_entities: { [EntityId]: { [EntityId | "everyone"]: true? } },
	dead_entities: { [EntityId]: true },
	decayable_entities: { [EntityId]: boolean },
}

export type System = {
	entities: { [EntityId]: boolean },
	overflow_items: { Item },
	power: number,
	has_heart: boolean,
	team: TeamId,
}

return {}
