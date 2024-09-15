local RunService = game:GetService "RunService"
local ServerScriptService = game:GetService "ServerScriptService"
local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"
local StarterGui = game:GetService "StarterGui"

local clone_assets = require(ReplicatedStorage.Shared.asset_server).clone
local util = require(ReplicatedStorage.Shared.util)
local types = require(ReplicatedStorage.Shared.types)

local tests = require(ServerScriptService.Server.tests)
local remotes_mod = require(ServerScriptService.Server.remotes)
local router_mod = require(ServerScriptService.Server.router)
local action_phase_mod = require(ServerScriptService.Server.action_phase)
local presets = require(ServerScriptService.Server.presets)
local turn_scheduler = require(ServerScriptService.Server.turn_scheduler)

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

type TeamData = types.TeamData
type Decision = types.Decision

if RunService:IsStudio() then
	tests.run_tests()
end

local grid
remotes_mod.get_hex_grid_data_remote.OnServerInvoke = function(player)
	while not grid or not grid:get_player_team(player) do
		task.wait(0.5)
	end
	local player_team = grid:get_player_team(player)
	return action_phase_mod.serialize_grid_for_team(grid, player_team.id)
end :: any

local join_data = if #Players:GetPlayers() > 0
	then Players:GetPlayers()[1]:GetJoinData()
	else Players.PlayerAdded:Wait():GetJoinData()

print(join_data)

grid = presets.my_map()
-- local grid = tests.extractor_filling_stockpile()
-- local grid = presets.testing_map()

_G.grid = grid

remotes_mod.decision_remote.OnServerEvent:Connect(function(plr: Player, data: { Decision })
	router_mod.on_decision(grid, plr, data)
end)

local function auto_add_player(plr: Player)
	local team_with_least_players = nil
	for _, team in grid.teams do
		if not team.is_player_team then
			continue
		end
		if not team_with_least_players or #team.players < #team_with_least_players.players then
			team_with_least_players = team
		end
	end
	if not team_with_least_players then
		error "no available teams"
	end
	table.insert(team_with_least_players.players, plr)
end

for _, plr in Players:GetPlayers() do
	auto_add_player(plr)
end

Players.PlayerAdded:Connect(function(plr)
	auto_add_player(plr)
	turn_scheduler.recalculate_skips(grid)
end)
Players.PlayerRemoving:Connect(function(plr)
	for _, team in grid.teams do
		util.table_remove_needle(team.players, plr)
	end
	util.table_remove_needle(grid.skipped, plr)

	turn_scheduler.recalculate_skips(grid)
end)

turn_scheduler.init(grid)
