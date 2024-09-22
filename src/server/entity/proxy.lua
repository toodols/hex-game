local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local registry_mod = require(script.Parent.registry)
local types = require(ReplicatedStorage.Shared.types)
local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)
local server_types = require(ServerScriptService.Server.types)

local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults

type Entity = types.Entity
type HexGrid = types.HexGrid
type ActionState = server_types.ActionState

registry["proxy"] = with_defaults {
	autogenerate_wires = true,
	on_completed = function(self: Entity, grid: HexGrid) end,
	influences = function(self: Entity, grid: HexGrid)
		local config = grid.entity_configurations[self.type]
		local neighbors = hex_grid_mod.neighbors_leq(self.primary_coordinate, config.range)
		for _, coord in neighbors do
			local cell = grid:get_cell(coord)
			if cell then
				cell.server_data.influences[self.id] = true
			end
		end
	end,
}

return {}
