local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)

type Entity = types.Entity
type EntityId = types.EntityId
type Item = types.Item
type Decision = types.Decision
type World = types.World
type TeamId = types.TeamId
type EffectiveDamage = types.DamageResult
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

-- this is distinct from shared_types.System
-- this is a temporal type that stores information
-- about items/power which is disposed of after one turn
-- todo: give this a different name
export type System = {
	entities: { [EntityId]: boolean },
	cells: { [EncodedCoordinate]: boolean },
	overflow_items: { Item },
	power: number,
	has_heart: boolean,
	team: TeamId,
}

return {}
