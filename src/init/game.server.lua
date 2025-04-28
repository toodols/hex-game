-- This is the init script for game.server.lua

local RunService = game:GetService "RunService"
local ServerScriptService = game:GetService "ServerScriptService"
local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"
local StarterGui = game:GetService "StarterGui"

local clone_assets = require(ReplicatedStorage.Shared.asset_server).clone
local util = require(ReplicatedStorage.Shared.util)
local types = require(ReplicatedStorage.Shared.types)
local team_mod = require(ReplicatedStorage.Shared.team)

type TeamData = types.TeamData
type Interaction = types.Interaction
type World = types.World

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

-- Load entities and effects into their registries
require(ServerScriptService.Server.effect_impls)
require(ServerScriptService.Server.entity_impls)
require(ReplicatedStorage.Shared.entity_impls)
require(ReplicatedStorage.Client.entity_impls) -- client also needs to be loaded for server-sided tests that deal with the client

local tests = require(ServerScriptService.Server.tests)
local remotes_mod = require(ServerScriptService.Server.remotes)
local router_mod = require(ServerScriptService.Server.router)
local serialize_mod = require(ServerScriptService.Server.serialize)
local presets = require(ServerScriptService.Server.presets)
local turn_scheduler = require(ServerScriptService.Server.turn_scheduler)
local updates_mod = require(ServerScriptService.Server.updates)
local server_util = require(ServerScriptService.Server.util)
local pow = require(ServerScriptService.Server.pow)
local pow_ext = ServerScriptService.Server.pow_ext

pow.init {
	permissions = {
		owner = {
			["195294332"] = 5,
		},
	},
	extras = pow_ext,
}

if RunService:IsStudio() then
	tests.run_tests()
end

local main_world
remotes_mod.get_world_data_remote.OnServerInvoke = function(player)
	-- todo: change this to return nil when world is not set up, and make the client poll instead
	while not main_world or not team_mod.team_of(main_world, player) do
		task.wait()
	end
	local player_team = team_mod.team_of(main_world, player)
	local serialized = serialize_mod.serialize_world_for_team(main_world, player_team.id)
	return serialized
end :: any

function republish_teams(world: World)
	updates_mod.add_update(world, {
		type = "teams",
		teams = util.table_map(world.teams, function(team)
			return serialize_mod.serialize_team(world, team)
		end),
		coalitions = world.coalitions,
	})
end

function start_game(teleport_data: { room: types.Room }?)
	local room = teleport_data and teleport_data.room
	local players_config = room and room.players
	print("Starting game with teleport data", game.HttpService:JSONEncode(teleport_data))
	main_world = presets[if room then room.map else "my_map"]()
	-- main_world = tests.server.decaying()

	_G.world = main_world

	remotes_mod.client_interaction_remote.OnServerEvent:Connect(function(plr: Player, data: { Interaction })
		local player_team = team_mod.team_of(main_world, plr)
		if not player_team then
			return
		end
		server_util.catch(function()
			router_mod.on_client_interaction(main_world, {
				player_team = player_team,
				data = data,
				plr = plr,
			})
		end, plr, data)
	end)

	local function auto_add_player(plr: Player)
		if players_config and players_config[plr.UserId] then
			local team = main_world.teams[players_config[plr.UserId].team]
			assert(team, "team not found")
			table.insert(team, plr)
		else
			local team_with_least_players = nil
			for _, team in main_world.teams do
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

	turn_scheduler.recalculate_skips(main_world)

	Players.PlayerAdded:Connect(function(plr)
		auto_add_player(plr)
		turn_scheduler.recalculate_skips(main_world)
		republish_teams(main_world)
	end)
	Players.PlayerRemoving:Connect(function(plr)
		for _, team in main_world.teams do
			util.table_remove_needle(team.players, plr)
		end
		util.table_remove_needle(main_world.skipped, plr)

		turn_scheduler.recalculate_skips(main_world)
		republish_teams(main_world)
	end)
end

local join_data = (
	if #Players:GetPlayers() > 0
		then Players:GetPlayers()[1]:GetJoinData()
		else Players.PlayerAdded:Wait():GetJoinData()
)

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
