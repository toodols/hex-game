local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)

type World = types.World
type CoalitionId = types.CoalitionId

-- game is concluded if only one or no coalitions remain
-- if there are no teams: the game is a draw
-- if there is only one coalition: those members win
function check_conclusion(world: World): (boolean, CoalitionId?)
	local team_status = {}
	for team_id, team in world.teams do
		if team.is_player_team then
			team_status[team_id] = false
		end
	end

	for _, entity in world:active_entities() do
		if team_status[entity.owner] ~= nil then
			team_status[entity.owner] = true
		end
	end

	local alive_coalitions = {}
	for coalition_id, coalition in world.coalitions do
		for _, team_id in coalition.teams do
			if team_status[team_id] then
				table.insert(alive_coalitions, coalition_id)
				break
			end
		end
	end

	if #alive_coalitions == 0 then
		return true, nil
	elseif #alive_coalitions == 1 then
		return true, alive_coalitions[1]
	else
		return false, nil
	end
end

function handle_conclusion(world: World)
	local is_concluded, winning_coalition = check_conclusion(world)
	if is_concluded then
		world.conclusion = {
			winning_coalition = winning_coalition,
		}
		world:add_update {
			type = "conclusion",
			conclusion = world.conclusion,
		}
	end
end

return {
	check_concluded = check_conclusion,
	handle_conclusion = handle_conclusion,
}
