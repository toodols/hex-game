local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
type HexCell = types.HexCell
type HexGrid = types.HexGrid
type Entity = types.Entity
type CubicCoordinate = types.CubicCoordinate
type Item = types.Item
type Recipe = types.Recipe
type ResearchId = types.ResearchId

export type SharedEntityBehavior = {
	type: string,
	init: ((self: Entity, grid: HexGrid) -> ())?,
	name: string,
	description: string,
	max_health: number,
	build_time: number,
	abilities: {
		[string]: {
			range: number,
			cost: { [Item]: number },
			damage: number,
		},
	},
	can_disable: boolean,
	required_research: { ResearchId }?,

	-- stockpile only
	inventory_capacity: number?,

	power_input: number?,
	output_power: number?,

	range: number?,

	-- list of offsets in addition to entity.primary_coordinate
	offsets: { CubicCoordinate },
	layer: number,
	cost: { [Item]: number },

	-- factory only
	recipes: { Recipe }?,
}

-- a higher layer indicates that damage will be passed to it first before the others
local layer = {
	wire = 0,
	building = 1,
	shield = 2,
}

function with_defaults(t: table): SharedEntityBehavior
	t.type = t.type or error "no type"
	t.init = t.init or function() end
	t.build_time = t.build_time or 0
	t.name = t.name or t.type
	t.description = t.description or "No description for " .. t.type
	t.max_health = t.max_health or 0
	t.can_disable = t.can_disable or false
	t.offsets = t.offsets or {}
	t.layer = t.layer or layer.building
	t.cost = t.cost or {}
	t.required_research = t.required_research
	t.recipes = t.recipes
	return t
end

local registry: { [string]: SharedEntityBehavior } = {}
return { layer = layer, registry = registry, with_defaults = with_defaults }
