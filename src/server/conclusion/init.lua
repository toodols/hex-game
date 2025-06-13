local ServerScriptService = game:GetService "ServerScriptService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local HttpService = game:GetService "HttpService"
local Players = game:GetService "Players"
local RunService = game:GetService "RunService"

local openskill = require(ServerScriptService.Server.openskill)
local types = require(ReplicatedStorage.Shared.types)
local turn_scheduler = require(ServerScriptService.Server.turn_scheduler)
local util = require(ReplicatedStorage.Shared.util)
local datastore_mod = require(ServerScriptService.Server.datastore)
local base64 = require(ReplicatedStorage.Shared.base64)
local structures = require(ServerScriptService.Server.structures)

local match_result_webhook = HttpService:GetSecret "MATCH_RESULT_WEBHOOK_URL"
match_result_webhook = match_result_webhook:AddPrefix "https://discord.com/api/webhooks/"

type World = types.World
type CoalitionId = types.CoalitionId
type PlayerId = types.PlayerId

-- game is concluded if only one or no coalitions remain
-- if there are no teams: the game is a draw
-- if there is only one coalition: those members win
function check_conclusion(world: World): (boolean, CoalitionId?)
	if _G.is_testing then
		return false, nil
	end
	if not world.global_configuration.conclusion_enabled then
		return false, nil
	end
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

function update_ratings(world: World, winning_coalition: CoalitionId?)
	local rate_teams = {}
	local rank = {}
	local rated_players = {}
	for _, coalition in world.coalitions do
		local rate_team = {}
		table.insert(rate_teams, rate_team)
		for _, team_id in coalition.teams do
			if team_id == winning_coalition then
				table.insert(rank, 0)
			else
				table.insert(rank, 1)
			end
			local team = world.teams[team_id]
			for _, player_id in team.historical_players do
				local player_data = world.player_data[tostring(player_id)]
				table.insert(rate_team, player_data.rating)
				table.insert(rated_players, player_id)
			end
		end
	end
	openskill.Rate(rate_teams, { rank = rank })
	for _, player_id in rated_players do
		local player_data = world.player_data[tostring(player_id)]
		player_data.rating_ordinal = openskill.Ordinal(player_data.rating)
		datastore_mod.set_player_data(player_id, player_data)
	end
	world:add_update {
		type = "player_data",
		player_data = world.player_data,
	}
end

function handle_conclusion(world: World)
	local is_concluded, winning_coalition = check_conclusion(world)
	if is_concluded then
		if world.turn_schedule ~= nil then
			turn_scheduler.turn_schedule_stop(world.turn_schedule)
			turn_scheduler.report_turn_time(world)
		end

		local data = base64.encode(structures.serialize_world(world))

		world.conclusion = {
			winning_coalition = winning_coalition,
			world_archive = data,
		}

		if world.global_configuration.rated then
			local old_player_ratings = {}
			for player_id, player_data in world.player_data do
				old_player_ratings[player_id] = player_data.rating_ordinal
			end

			update_ratings(world, winning_coalition)

			local is_draw = winning_coalition == nil
			local winning_teams = if winning_coalition ~= nil then world.coalitions[winning_coalition].teams else nil

			if not RunService:IsStudio() and match_result_webhook ~= nil then
				local content = ""
				content ..= table.concat(
					util.table_filter_map(world.teams, function(team)
						if not team.is_player_team then
							return nil
						end
						local did_win = table.find(winning_teams, team.id) ~= nil
						return `# {team.name} ({if is_draw then "DRAW" elseif did_win then "WIN" else "LOSE"})\n`
							.. table.concat(
								util.table_map(team.historical_players, function(player_id: PlayerId)
									local player_data = world.player_data[tostring(player_id)]
									local player = Players:GetPlayerByUserId(player_id)
									local player_name = if player
										then player.Name
										else Players:GetNameFromUserIdAsync(player_id)

									return ` - {player_name} ({util.round2(old_player_ratings[tostring(player_id)])} -> {util.round2(
										player_data.rating_ordinal
									)})`
								end),
								"\n"
							)
					end),
					"\n"
				)

				HttpService:PostAsync(
					match_result_webhook,
					HttpService:JSONEncode {
						content = content,
					}
				)
			end
		end

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
