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
type EncodedCoordinate = types.EncodedCoordinate
type Damage = types.Damage

export type DamageResult = {
	-- whether to propagate damage to the next layer(s)
	propagate: boolean,
	-- how much damage was applied
	effective: number,
}
export type ActionState = {
	will_be_destroyed_entities: { [EntityId]: boolean },
	systems: { System },
	system_by_entity_id: { [EntityId]: System },
	system_by_cell: { [EncodedCoordinate]: System },
}

export type System = {
	entities: { [EntityId]: boolean },
	cells: { [EncodedCoordinate]: boolean },
	overflow_items: { Item },
	power: number,
	has_heart: boolean,
	team: TeamId,
}

return {}
