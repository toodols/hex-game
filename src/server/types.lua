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
type System = types.System

export type DamageResult = {
	-- whether to propagate damage to the next layer(s)
	propagate: boolean,
	-- how much damage was applied
	effective: number,
}
export type ActionState = {
	will_be_destroyed_entities: { [EntityId]: boolean },
	systems: { SystemExtended },
	system_by_entity_id: { [EntityId]: SystemExtended },
	system_by_cell: { [EncodedCoordinate]: SystemExtended },
}

export type SystemExtended = System & {
	overflow_items: { Item },
	power: number,
	has_heart: boolean,
	team: TeamId,
}

export type PlayerInfo = {
	team: TeamId,
	player: Player?,
}

return {}
