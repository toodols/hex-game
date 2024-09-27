local ReplicatedStorage = game:GetService "ReplicatedStorage"
local util = require(ReplicatedStorage.Shared.util)
local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)
local types = require(ReplicatedStorage.Shared.types)
type HexGrid = types.HexGrid

-- a presence prevents enemy teams from building on that cell
function compute_presence(grid: HexGrid)
	local neutral_team = grid.neutral_team
	for _, cell in grid.cells do
		local owner
		for entity_id in cell.entities do
			local entity = grid.entities[entity_id]
			if entity.owner ~= neutral_team and entity.status ~= "blueprint" and not entity.is_destroyed then
				owner = entity.owner
			end

			-- most entities do not impose a presence
			-- barriers do
			if entity.owner == neutral_team and entity.type == "barrier" then
				owner = neutral_team
			end
		end
		cell.owner = owner
	end
	for _, cell in grid.cells do
		local presence = {}
		for _, coord in hex_grid_mod.neighbors_leq(cell.coordinate, 1) do
			local neighbor = grid:get_cell(coord)
			-- teams impose a presence in r<=1
			-- neutral teams impose a presence in r=0
			if
				neighbor
				and neighbor.owner
				and (neighbor.owner ~= neutral_team or hex_grid_mod.coords_eq(cell.coordinate, coord))
			then
				presence[neighbor.owner] = true
			end
		end
		-- if not util.deep_equal(presence, cell.server_data.presence) then
		-- if mark_dirty then
		-- 	cell.server_data.dirty = true
		-- end
		-- end

		cell.server_data.presence = presence
	end
end

return {
	compute_presence = compute_presence,
}
