local RunService = game:GetService "RunService"
local ServerScriptService = game:GetService "ServerScriptService"
local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"
local StarterGui = game:GetService "StarterGui"

local clone_assets = require(ReplicatedStorage.Shared.asset_server).clone
local util = require(ReplicatedStorage.Shared.util)
local types = require(ReplicatedStorage.Shared.types)

type TeamData = types.TeamData
type Interaction = types.Interaction
type HexGrid = types.HexGrid

-- Copy assets for client use
local destination = Instance.new "Folder"
destination.Parent = ReplicatedStorage
destination.Name = "ReplicatedAssets"

local server_assets = workspace:FindFirstChild "Assets"
server_assets.Parent = ServerStorage

workspace:FindFirstChild("Nonassets"):Destroy()

StarterGui:ClearAllChildren()

clone_assets({
	Entities = true,
	Tiles = true,
	Billboards = true,
	Effects = true,
}, server_assets, destination)

local tests = require(ServerScriptService.Server.tests)
local remotes_mod = require(ServerScriptService.Server.remotes)
local router_mod = require(ServerScriptService.Server.router)
local serialize_mod = require(ServerScriptService.Server.serialize)
local presets = require(ServerScriptService.Server.presets)
local turn_scheduler = require(ServerScriptService.Server.turn_scheduler)
local updates_mod = require(ServerScriptService.Server.updates)

if RunService:IsStudio() then
	tests.run_tests()
end

local grid
remotes_mod.get_hex_grid_data_remote.OnServerInvoke = function(player)
	-- todo: change this to return nil when grid is not set up, and make the client poll instead
	while not grid or not grid:get_player_team(player) do
		task.wait()
	end
	local player_team = grid:get_player_team(player)
	local serialized = serialize_mod.serialize_grid_for_team(grid, player_team.id)
	return serialized
end :: any

function republish_teams(grid: HexGrid)
	updates_mod.add_update(grid, {
		type = "teams",
		teams = util.table_map(grid.teams, function(team)
			return serialize_mod.serialize_team(grid, team)
		end),
		coalitions = grid.coalitions,
	})
end

function start_game(teleport_data: { room: types.Room }?)
	local room = teleport_data and teleport_data.room
	local players_config = room and room.players
	grid = presets[if room then room.map else "my_map"]()

	_G.grid = grid

	remotes_mod.client_interaction_remote.OnServerEvent:Connect(function(plr: Player, data: { Interaction })
		router_mod.on_client_interaction(grid, plr, data)
	end)

	local function auto_add_player(plr: Player)
		if players_config and players_config[plr.UserId] then
			local team = grid.teams[players_config[plr.UserId].team]
			assert(team, "team not found")
			table.insert(team, plr)
		else
			local team_with_least_players = nil
			for _, team in grid.teams do
				if not team.is_player_team then
					continue
				end
				if not team_with_least_players or #team.players < #team_with_least_players.players then
					team_with_least_players = team
				end
			end
			assert(team_with_least_players, "no teams found")
			table.insert(team_with_least_players.players, plr)
		end
	end

	for _, plr in Players:GetPlayers() do
		auto_add_player(plr)
	end

	turn_scheduler.recalculate_skips(grid)

	Players.PlayerAdded:Connect(function(plr)
		auto_add_player(plr)
		turn_scheduler.recalculate_skips(grid)
		republish_teams(grid)
	end)
	Players.PlayerRemoving:Connect(function(plr)
		for _, team in grid.teams do
			util.table_remove_needle(team.players, plr)
		end
		util.table_remove_needle(grid.skipped, plr)

		turn_scheduler.recalculate_skips(grid)
		republish_teams(grid)
	end)
end

local join_data = (
	if #Players:GetPlayers() > 0
		then Players:GetPlayers()[1]:GetJoinData()
		else Players.PlayerAdded:Wait():GetJoinData()
)
-- join_data = {
-- 	TeleportData = {
-- 		room = {
-- 			map = "tutorial_map",
-- 			players = {
-- 				["195294332"] = {
-- 					team = "3",
-- 				},
-- 			},
-- 		},
-- 	},
-- }

if join_data and join_data.TeleportData and join_data.TeleportData.room then
	local needed_plrs_count = 0
	local needed_plrs_map = {}

	for member_id in join_data.TeleportData.room.players do
		if not Players:GetPlayerByUserId(member_id) then
			needed_plrs_map[member_id] = true
			needed_plrs_count += 1
		end
	end

	if needed_plrs_count == 0 then
		start_game(join_data.TeleportData)
	else
		local connection
		connection = Players.PlayerAdded:Connect(function(plr)
			if needed_plrs_map[tostring(plr.UserId)] then
				needed_plrs_map[tostring(plr.UserId)] = nil
				needed_plrs_count -= 1
				if needed_plrs_count == 0 then
					connection:Disconnect()
					start_game(join_data.TeleportData)
				end
			end
		end)
	end
else
	start_game()
end
