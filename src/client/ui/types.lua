local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)

type CubicCoordinate = types.CubicCoordinate
type Entity = types.Entity
type EntityId = types.EntityId
type EncodedCoordinate = types.EncodedCoordinate

export type SelectionMode = {
	type: "select_cells",
	selected: { [EncodedCoordinate]: true },
} | {
	type: "select_some_cell",
	candidates: { [EncodedCoordinate]: true },
	on_selected: (cell: CubicCoordinate) -> nil,
} | {
	type: "select_some_cell_group",
	candidates: { [EncodedCoordinate]: { EncodedCoordinate } },
	on_selected: (cell: CubicCoordinate) -> nil,
} | {
	type: "show_cells",
	cells: { [EncodedCoordinate]: true },
} | {
	type: "show_one_entity",
	entity_id: EntityId,
} | {
	type: "show_one_entity",
	entity: Entity,
}

export type Submenu = { type: nil } | {
	type: "build",
	cell: CubicCoordinate,
} | {
	type: "item_filters",
	entity_id: EntityId,
} | {
	type: "research",
	entity_id: EntityId,
} | {
	type: "recipes",
	entity_id: EntityId,
}

return {}
