local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)

type HexCell = types.HexCell
type World = types.World
type Entity = types.Entity
type CubicCoordinate = types.CubicCoordinate
type Item = types.Item
type Recipe = types.Recipe
type ResearchId = types.ResearchId
type EntityConfiguration = types.EntityConfiguration

-- a higher layer indicates that damage will be passed to it first before the others
local LAYER = {
	deposit = 0,
	vertex = 1,
	modifier = 2,
	building = 3,
	-- shield = 4,
}

local registry: { [string]: EntityConfiguration } = {}

-- for typechecking
type PartialEntityConfiguration = {
	type: string,
	init: ((self: Entity) -> ())?,
	build_time: number?,
	buildable: boolean?,
	name: string?,
	description: string?,
	short_description: string?,
	max_health: number?,
	can_disable: boolean?,
	offsets: { CubicCoordinate }?,
	layer: number?,
	cost: { [Item]: number }?,
	required_research: { ResearchId }?,
	recipes: { Recipe }?,
	required_unlockable: { string }?,
	can_revive: boolean?,
}

function with_defaults(t: PartialEntityConfiguration): EntityConfiguration
	t.type = t.type or error "no type"
	t.init = t.init or function() end
	t.build_time = t.build_time or 0
	-- this entity may be built by the player?
	t.buildable = if t.buildable ~= nil then t.buildable else true
	t.name = t.name or t.type
	t.description = t.description or "No description for " .. t.type
	t.short_description = t.short_description or t.description
	t.max_health = t.max_health or 0
	t.can_disable = t.can_disable or false
	t.offsets = t.offsets or {}
	t.layer = t.layer or LAYER.building
	t.cost = t.cost or {}
	t.required_research = t.required_research or {}
	t.recipes = t.recipes
	t.required_unlockable = t.required_unlockable or {}
	t.can_revive = t.can_revive or false
	return t :: any
end

function get_effective_health(entity: Entity): number
	local health = entity.health
	for _, effect in entity.effects do
		if effect.type == "shield" then
			health += effect.health
		end
	end
	return health
end

function create_configuration(): { [string]: EntityConfiguration }
	return util.deep_copy(registry)
end

return {
	LAYER = LAYER,
	registry = registry,
	with_defaults = with_defaults,
	get_effective_health = get_effective_health,
	create_configuration = create_configuration,
}
