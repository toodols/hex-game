-- i love chatgpt
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"
local types = require(ReplicatedStorage.Shared.types)
local coords_mod = require(script.Parent.coords)

type HexGrid = types.HexGrid
type HexCell = types.HexCell
type CubicCoordinate = types.CubicCoordinate
type TeamId = types.TeamId

function blocked(grid: HexGrid, cell: HexCell, team: TeamId?)
	local visible = if RunService:IsClient()
		then cell.visible_for_team
		else require(game.ServerScriptService.Server.visibility).cell_visibility(
			team and cell.server_data.visibility[team]
		)
	if team ~= nil and not visible then
		return true
	end
	for entity_id in cell.entities do
		local entity = grid.entities[entity_id]
		if entity and entity.owner ~= team then
			return true
		end
	end
	return false
end

function coords_round(coord: { number }): { CubicCoordinate }
	local q = math.floor(coord[1] + 0.5)
	local r = math.floor(coord[2] + 0.5)
	local s = math.floor(coord[3] + 0.5)

	local q_diff = math.abs(q - coord[1])
	local r_diff = math.abs(r - coord[2])
	local s_diff = math.abs(s - coord[3])

	local results = {}

	-- Check for boundaries and add the neighboring cells it falls between
	if q_diff == 0.5 then
		table.insert(results, { q + (q > coord[1] and -1 or 1), r, s })
	end
	if r_diff == 0.5 then
		table.insert(results, { q, r + (r > coord[2] and -1 or 1), s })
	end
	if s_diff == 0.5 then
		table.insert(results, { q, r, s + (s > coord[3] and -1 or 1) })
	end

	if q_diff > r_diff and q_diff > s_diff then
		q = -r - s
	elseif r_diff > s_diff then
		r = -q - s
	else
		s = -q - r
	end

	table.insert(results, { q == -0 and 0 or q, r == -0 and 0 or r, s == -0 and 0 or s })

	return results
end

function hex_line(start, finish)
	local N = math.max(math.abs(start[1] - finish[1]), math.abs(start[2] - finish[2]), math.abs(start[3] - finish[3]))
	local results = {}
	for i = 0, N do
		local t = i / N
		local interpolated = coords_mod.coords_lerp(start, finish, t)
		table.insert(results, coords_round(interpolated))
	end
	return results
end

function line_of_sight(grid: HexGrid, start: CubicCoordinate, finish: CubicCoordinate, team: TeamId?)
	if coords_mod.coords_eq(start, finish) then
		return true
	end
	local line = hex_line(start, finish)
	for i, coordinates in line do
		local ok = false
		for _, coordinate in coordinates do
			local cell = grid:get_cell(coordinate)
			if not cell then
				error "no cell"
			end
			if coords_mod.coords_eq(coordinate, finish) or not blocked(grid, cell, team) then
				ok = true
			end
		end
		if not ok then
			return false
		end
	end
	return true
end

return {
	blocked = blocked,
	line_of_sight = line_of_sight,
}
