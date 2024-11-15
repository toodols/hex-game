local ReplicatedStorage = game:GetService "ReplicatedStorage"
local registry_mod = require(script.Parent.registry)
local asset_server = require(ReplicatedStorage.Shared.asset_server)
local types = require(ReplicatedStorage.Shared.types)
local hex_grid = require(ReplicatedStorage.Shared.hex_grid)
local util = require(ReplicatedStorage.Shared.util)
local shared_entity_mod = require(ReplicatedStorage.Shared.entity)
local model = asset_server.load "Entities/Wires"

type HexGrid = types.HexGrid
type HexCell = types.HexCell
type Entity = types.Entity

function update_wire_artifacts(self: Entity, grid: HexGrid)
	local instance = grid.entity_instance_map[self.id]
	util.set_transparency(instance:FindFirstChild "0,0,0", registry_mod.transparency[self.status])

	for _, neighbor_coord in (hex_grid.neighbors_eq(self.primary_coordinate, 1)) do
		local neighbor_cell = grid:get_cell(neighbor_coord)
		local neighbor_offset = hex_grid.coords_sub(self.primary_coordinate, neighbor_coord)
		local wire_instance = instance:FindFirstChild(hex_grid.encode_coord(neighbor_offset))
		if wire_instance then
			local neighbor_wire = grid:query_entity({
				primary_coordinate = neighbor_coord,
				type = "wires",
				owner = self.owner,
			})[1]
			util.set_transparency(
				wire_instance,
				if neighbor_cell and neighbor_wire then registry_mod.transparency[self.status] else 1
			)
		end
	end
end
registry_mod.registry.wires = registry_mod.with_defaults {
	model = model,
	update = function(self: Entity, grid: HexGrid, new: Entity) end,
	status_changed = function(self, grid)
		update_wire_artifacts(self, grid)
	end,
	neighbor_changed = function(self: Entity, grid: HexGrid)
		update_wire_artifacts(self, grid)
	end,
	init = function(self: Entity, grid: HexGrid)
		update_wire_artifacts(self, grid)
	end,
}

return {}
