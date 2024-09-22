local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)

type CubicCoordinate = types.CubicCoordinate

export type SelectionMode = {
	type: "select_cells",
	selected: { [Instance]: true },
} | {
	type: "select_direction",
	origin: CubicCoordinate,
	candidates: { [Instance]: { [Instance]: true } },
	on_selected: (instance: Instance) -> (),
} | {
	type: "show_cells",
	cells: { [Instance]: true },
}
return {}
