local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)
local cell_visibility = require(ServerScriptService.Server.visibility).cell_visibility
local server_types = require(ServerScriptService.Server.types)

type HexGrid = types.HexGrid
type TeamId = types.TeamId
type EncodedCoordinate = types.EncodedCoordinate
type CubicCoordinate = types.CubicCoordinate
type HexCell = types.HexCell
type ActionState = server_types.ActionState

-- Computes visibility for each team and returns a set of cells for each team that has changed to visible
function compute_visibility(grid: HexGrid): { [TeamId]: { [EncodedCoordinate]: boolean } }
	local changed_to_visible: { [TeamId]: { [EncodedCoordinate]: boolean } } = {}
	local old_vis: { [EncodedCoordinate]: { [TeamId]: any } } = {}
	-- reset server_data.visibility for all cells
	for encoded_coord, cell in grid.cells do
		old_vis[encoded_coord] = cell.server_data.visibility
		cell.server_data.visibility = {}
	end

	local function add_visibility(coord: CubicCoordinate, team_id: TeamId, type: string)
		local encoded_coord = hex_grid_mod.encode_coord(coord)
		local cell = grid:get_cell(coord)
		if not cell then
			return
		end
		changed_to_visible[team_id] = changed_to_visible[team_id] or {}
		old_vis[encoded_coord] = old_vis[encoded_coord] or {}
		if not cell_visibility(old_vis[encoded_coord][team_id]) then
			changed_to_visible[team_id][encoded_coord] = true
		end
		cell.server_data.visibility[team_id] = cell.server_data.visibility[team_id] or {}
		cell.server_data.visibility[team_id][type] = true
	end

	-- loop through each entity and apply r=2
	-- some other entities will have extra illuminations
	for _, entity in grid:active_entities() do
		if entity.status ~= "complete" or entity.is_destroyed then
			continue
		end

		-- occupying a portal gives r<=1 visibility for each connected portal
		local cell = grid:get_cell(entity.primary_coordinate)
		if cell.type == "portal" and cell.portal.open then
			for _, connected in cell.portal.group do
				-- ignore self
				if hex_grid_mod.coords_eq(connected, entity.primary_coordinate) then
					continue
				end
				local neighbors = hex_grid_mod.neighbors_leq(connected, 1)
				for _, coord in neighbors do
					add_visibility(coord, entity.owner, "portal")
				end
			end
		end

		-- local cell = grid:get_cell(entity.primary_coordinate)
		-- local server_behavior = server_entity_mod.registry[entity.type]
		local illuminated = hex_grid_mod.neighbors_leq(entity.primary_coordinate, 2)
		if entity.type == "scout" then
			illuminated = hex_grid_mod.neighbors_leq(entity.primary_coordinate, 3)
		end
		for _, neighbor_coord in illuminated do
			add_visibility(neighbor_coord, entity.owner, "illumination")
		end
	end

	for _, team in grid.teams do
		if team.server_data.visibility == "fogless" or team.server_data.visibility == "perfect" then
			changed_to_visible[team.id] = changed_to_visible[team.id] or {}
			for _, cell in grid.cells do
				local encoded_coord = hex_grid_mod.encode_coord(cell.coordinate)
				old_vis[encoded_coord] = old_vis[encoded_coord] or {}
				if not cell_visibility(old_vis[encoded_coord][team.id]) then
					changed_to_visible[team.id][encoded_coord] = true
				end
				cell.server_data.visibility[team.id] = cell.server_data.visibility[team.id] or {}
				cell.server_data.visibility[team.id].fogless = true
			end
		end
	end

	return changed_to_visible
end

return {
	compute_visibility = compute_visibility,
}
