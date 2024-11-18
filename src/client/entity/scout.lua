local ReplicatedStorage = game:GetService "ReplicatedStorage"
local registry_mod = require(script.Parent.registry)
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local asset_server = require(ReplicatedStorage.Shared.asset_server)
local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)

type Entity = types.Entity
type HexGrid = types.HexGrid

local indicator_template = asset_server.load "Effects/AttackArrow"
local model = asset_server.load "Entities/Scout"

local function update_model(self: Entity, grid: HexGrid)
	local instance = grid.entity_instance_map[self.id]
	local attack = util.table_find_pred(self.queued_decisions, function(v)
		return v.type == "ability" and v.ability_type == "scout_attack"
	end)

	local indicator: PVInstance? = instance:FindFirstChild "AttackArrow"
	if attack then
		if indicator then
			-- todo: make it animate?
			(indicator :: any):PivotTo(
				CFrame.lookAt(
					instance:GetPivot().Position,
					instance:GetPivot().Position
						+ hex_grid_mod.into_vec3(hex_grid_mod.coords_sub(attack.coordinate, self.primary_coordinate))
				)
			)
		else
			indicator = indicator_template:Clone();
			(indicator :: any).Parent = instance;
			(indicator :: any):PivotTo(
				CFrame.lookAt(
					instance:GetPivot().Position,
					instance:GetPivot().Position
						+ hex_grid_mod.into_vec3(hex_grid_mod.coords_sub(attack.coordinate, self.primary_coordinate))
				)
			)
		end
	else
		if indicator then
			indicator:Destroy()
		end
	end
end

registry_mod.registry.scout = registry_mod.with_defaults {
	model = model,
	update = function(self: Entity, grid: HexGrid, old: Entity)
		update_model(self, grid)
	end,
	init = function(self: Entity, grid: HexGrid)
		update_model(self, grid)
	end,
}

return {}
