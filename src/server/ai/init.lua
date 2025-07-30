local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local world_mod = require(ReplicatedStorage.Shared.world)
local coords_mod = require(ReplicatedStorage.Shared.coords)
type Interaction = types.Interaction
type World = types.World
type TeamData = types.TeamData

type Memory = {}
type ConfigProfile = {}
type CandidateAction = {
	action: Interaction,
	score: number,
}

-- look for the closest bar deposit that is not occupied
function claim_bar_deposit(
	world: World,
	team: TeamData,
	config_profile: ConfigProfile,
	memory: Memory
): CandidateAction?
	local heart = world:query_entity {
		type = "heart",
		owner = team.id,
	}
	local candidate_deposits = {}
	for _, cell in world_mod.coords_filter(world, coords_mod.neighbors_leq(heart.primary_coordinate, 5)) do
		for _, entity in cell.entities do
			if entity.type == "deposit" and entity.deposit_type == "bar_deposit" then
				table.insert(candidate_deposits, entity)
			end
		end
	end

	return nil
end

local actions = { claim_bar_deposit }

function decide(world: World, team: TeamData, config_profile: ConfigProfile, memory: Memory)
	local interactions = {}
	while true do
		local best_action = { action = nil, score = 0 }
		for _, action in actions do
			local candidate = action(world, memory)
			if candidate and candidate.score > best_action.score then
				best_action = candidate
			end
		end
		if best_action.score > 0 then
			table.insert(interactions, best_action.action)
		else
			break
		end
	end
	return interactions
end

return {
	decide = decide,
}
