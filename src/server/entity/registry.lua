local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)
local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)
local remotes_mod = require(ServerScriptService.Server.remotes)

type Damage = types.Damage
type HexCell = types.HexCell
type HexGrid = types.HexGrid
type PartialHexGrid = types.PartialHexGrid
type Entity = types.Entity
type ActionState = server_types.ActionState
type CellType = types.CellType
type TeamId = types.TeamId
type CubicCoordinate = types.CubicCoordinate

export type DamageResult = {
	-- whether to propagate damage to the next layer(s)
	propagate: boolean,
	-- how much damage was applied
	effective: number,
}

export type ServerEntityBehavior = {
	type: string,
	init: (self: Entity, grid: HexGrid) -> (),

	-- called at the start of every action phase
	tick: (self: Entity, grid: HexGrid, action_state: ActionState?) -> (),
	built_on: { CellType },
	take_damage: (self: Entity, grid: HexGrid, damage: Damage, gauge: number) -> DamageResult,
	neighbor_changed: (self: Entity, grid: HexGrid, action_state: ActionState?) -> (),
	get_illumination: (self: Entity, grid: HexGrid) -> { CubicCoordinate },
	on_completed: (self: Entity, grid: HexGrid, action_state: ActionState?) -> (),
	influences: ((self: Entity, grid: HexGrid) -> ())?,
	-- laboratory only
	on_research_completed: (self: Entity, grid: HexGrid, research_id: string) -> ()?,
	autogenerate_wires: boolean?,
}

function default_take_damage(entity: Entity, grid: HexGrid, damage: Damage, gauge: number): DamageResult
	if entity.is_destroyed then
		error "Destroyed entities should not receive damage"
	end

	local effective = math.min(gauge, entity.health)

	return {
		propagate = (entity.health == effective) and (effective > 0 or entity.health == 0),
		effective = effective,
	}
end

local registry: { [string]: ServerEntityBehavior } = {}

function with_defaults(behavior: table): ServerEntityBehavior
	behavior.take_damage = behavior.take_damage or default_take_damage
	behavior.init = behavior.init or function(self) end
	behavior.neighbor_changed = behavior.neighbor_changed or function(...) end
	behavior.tick = behavior.tick or function(...) end
	behavior.on_completed = behavior.on_completed or function(...) end
	behavior.built_on = behavior.built_on or {}
	behavior.influences = behavior.influences or function() end
	behavior.illuminates = function(self, grid)
		return {}
	end
	return behavior
end

return { registry = registry, with_defaults = with_defaults }
