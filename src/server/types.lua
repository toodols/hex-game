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
type PlayerId = types.PlayerId
type HexCell = types.HexCell
type Quest = types.Quest

export type DamageResult = {
	-- whether to propagate damage to the next layer(s)
	propagate: boolean,
	-- how much damage was applied
	effective: number,
}

export type PlayerInfo = {
	team: TeamId,
	player: Player?,
}

export type ViewTarget = {
	team: TeamId,
	player: PlayerId,
} | {
	team: TeamId,
	player: nil,
} | {
	team: nil,
	player: nil,
}

export type ViewCache = {
	cells: { [EncodedCoordinate]: HexCell }?,
	systems: { System }?,
	entities: { [EntityId]: Entity }?,
	quests: { [string]: Quest }?,
}

-- this is a cache for personalized data
export type ViewContext = {
	[TeamId]: {
		[PlayerId]: ViewCache,
	},
}

export type InteractionResult = {
	success: boolean,
	error_msg: string?,
	error_type: number,
	dirty_entities: { [EntityId]: boolean },
}

return {}
