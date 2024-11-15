local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)
local shared_entity_mod = require(ReplicatedStorage.Shared.entity)

type Damage = types.Damage
type HexCell = types.HexCell
type HexGrid = types.HexGrid
type PartialHexGrid = types.PartialHexGrid
type Entity = types.Entity
type ActionState = server_types.ActionState
type CellType = types.CellType
type TeamId = types.TeamId
type CubicCoordinate = types.CubicCoordinate
type DamageResult = server_types.DamageResult
type EntityEvent = types.EntityEvent

export type ServerEntityBehavior = {
	type: string,
	init: (self: Entity, grid: HexGrid) -> (),

	-- called at the start of every action phase
	tick: (self: Entity, grid: HexGrid, action_state: ActionState?) -> (),
	built_on: { CellType },

	get_illumination: (self: Entity, grid: HexGrid) -> { CubicCoordinate },
	on_completed: (self: Entity, grid: HexGrid) -> (),
	influences: ((self: Entity, grid: HexGrid) -> ())?,
	-- laboratory only
	on_research_completed: (self: Entity, grid: HexGrid, research_id: string) -> ()?,
	autogenerate_wires: boolean?,
	on_event: (self: Entity, grid: HexGrid, event: EntityEvent, action_state: ActionState) -> (),
}

local registry: { [string]: ServerEntityBehavior } = {}

function with_defaults(behavior: any): ServerEntityBehavior
	behavior.init = behavior.init or function(self) end
	behavior.tick = behavior.tick or function(...) end
	behavior.on_completed = behavior.on_completed or function(...) end
	behavior.built_on = behavior.built_on or {}
	behavior.influences = behavior.influences or function() end
	behavior.on_event = behavior.on_event or function() end
	behavior.illuminates = function(self, grid)
		return {}
	end
	return behavior
end

return { registry = registry, with_defaults = with_defaults }
