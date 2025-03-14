local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local registry_mod = require(script.Parent.registry)
local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)
local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults

type Entity = types.Entity
type HexGrid = types.HexGrid

registry.altar = with_defaults {
	autogenerates_vertex = true,
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
