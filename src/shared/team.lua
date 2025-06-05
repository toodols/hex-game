local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
type World = types.World
type TeamId = types.TeamId
type TeamData = types.TeamData

function get_allies(world: World, team: TeamId): { TeamId }
	for _, coalition in world.coalitions do
		if table.find(coalition.teams, team) then
			return coalition.teams
		end
	end
	-- no coalition found, ally is itself
	return { team }
end

function is_allied(world: World, team1: TeamId, team2: TeamId): boolean
	if team1 == team2 then
		return true
	end
	for _, coalition in world.coalitions do
		if table.find(coalition.teams, team1) and table.find(coalition.teams, team2) then
			return true
		end
	end
	return false
end

function team_of(world: World, player: Player): TeamData?
	if player == nil then
		return nil
	end
	for _, team in world.teams do
		if table.find(team.players, player.UserId) then
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
