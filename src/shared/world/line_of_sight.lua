-- i love chatgpt
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"
local types = require(ReplicatedStorage.Shared.types)
local coords_mod = require(ReplicatedStorage.Shared.coords)

type World = types.World
type HexCell = types.HexCell
type CubicCoordinate = types.CubicCoordinate
type TeamId = types.TeamId

function blocked(world: World, cell: HexCell, team: TeamId?)
	local visible = if RunService:IsClient()
		then cell.visible_for_team
		else require(game.ServerScriptService.Server.visibility).cell_visibility(
			team and cell.server_data.visibility[team]
		)
	if team ~= nil and not visible then
		return true
	end
	for entity_id in cell.entities do
		local entity = world.entities[entity_id]
		if
			entity
			and entity.status == "complete"
			and entity.owner ~= team
			and entity.type ~= "vertex"
			and entity.type ~= "grave"
		then
			return true
		end
	end
	return false
end

function hex_line(start: CubicCoordinate, finish: CubicCoordinate): { { CubicCoordinate } }
	local N = math.max(math.abs(start[1] - finish[1]), math.abs(start[2] - finish[2]), math.abs(start[3] - finish[3]))
	local results = {}
	for i = 0, N do
		local t = i / N
		local interpolated = coords_mod.coords_lerp(start, finish, t)
		table.insert(results, coords_mod.coords_round(interpolated))
	end
	return results
end

function line_of_sight(world: World, start: CubicCoordinate, finish: CubicCoordinate, team: TeamId?)
	if coords_mod.coords_eq(start, finish) then
		return true
	end
	local line = hex_line(start, finish)
	for i, coordinates in line do
		local ok = false
		for _, coordinate in coordinates do
			local cell = world:get_cell(coordinate)
			if cell == nil then
				error "no cell"
			end
			if coords_mod.coords_eq(coordinate, finish) or not blocked(world, cell, team) then
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
