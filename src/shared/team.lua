local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
type HexGrid = types.HexGrid
type TeamId = types.TeamId
type TeamData = types.TeamData

function get_allies(grid: HexGrid, team: TeamId): { TeamId }
	for _, coalition in grid.coalitions do
		if table.find(coalition.teams, team) then
			return coalition.teams
		end
	end
	-- no coalition found, ally is itself
	return { team }
end

function is_allied(grid: HexGrid, team1: TeamId, team2: TeamId): boolean
	for _, coalition in grid.coalitions do
		if table.find(coalition.teams, team1) and table.find(coalition.teams, team2) then
			return true
		end
	end
	return team1 == team2
end

function team_of(grid: HexGrid, player: Player): TeamData?
	for _, team in grid.teams do
		if table.find(team.players, player) then
			return team
		end
	end
	return nil
end

return {
	get_allies = get_allies,
	is_allied = is_allied,
	team_of = team_of,
}
