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
	Items = true,
}, server_assets, destination)

require(ReplicatedStorage.Shared.effect_impls)
require(ReplicatedStorage.Shared.entity_impls)
require(ServerScriptService.Server.effect_impls)
require(ServerScriptService.Server.entity_impls)
require(ReplicatedStorage.Client.entity_impls) -- client also needs to be loaded for server-sided tests that deal with the client

local tests = require(ServerScriptService.Server.tests)
local remotes_mod = require(ServerScriptService.Server.remotes)
local router_mod = require(ServerScriptService.Server.router)
local serialize_mod = require(ServerScriptService.Server.serialize)
local presets = require(ServerScriptService.Server.presets)
local turn_scheduler = require(ServerScriptService.Server.turn_scheduler)
local updates_mod = require(ServerScriptService.Server.updates)
local server_util = require(ServerScriptService.Server.util)
local datastore_mod = require(ServerScriptService.Server.datastore)
require(ServerScriptService.Server.teleport)

if ServerScriptService.Server:FindFirstChild "pow" then
	local pow = require(ServerScriptService.Server.pow)

	pow.init {
		permissions = {
			owner = {
				["195294332"] = 5,
			},
		},
		extras_shared = { ServerScriptService.Server.pow_extras.extras_shared },
		extras_server = { ServerScriptService.Server.pow_extras.extras_server },
	}
else
	warn "Did not find pow. Cannot initialize."
end

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
	local serialized = serialize_mod.serialize_world(main_world, {}, { team = player_team.id, player = player.UserId })
	return serialized
end :: any

function republish_teams(world: World)
	world:add_update {
		type = "teams",
		teams = util.table_map(world.teams, function(team)
			return serialize_mod.serialize_team(world, team)
		end),
		coalitions = world.coalitions,
	}
end

function start_game(teleport_data: { room: types.Room }?)
	local room = teleport_data and teleport_data.room
	-- or { map = "my_map", players = { ["-1"] = { team = 4 }, ["-2"] = { team = 3 } } }
	local players_config = room and room.players
	print("Starting game with teleport data", game.HttpService:JSONEncode(teleport_data))
	-- main_world = tests.server.weird_presence_after_load()
	main_world = presets[if room then room.map else "my_map"]()
	-- main_world = tests.server.phony_generates_tek_on_death()

	_G.world = main_world

	local team_instances = {}
	for i, team_data in main_world.teams do
		local team = Instance.new "Team"
		team.Parent = game:GetService "Teams"
		team.Name = team_data.name
		-- todo: support color sequence
		team.TeamColor = BrickColor.new(team_data.color.color)
		team_instances[i] = team
	end

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
		if players_config then
			local config = players_config[tostring(plr.UserId)]
			local team: TeamData
			if config and config.team then
				team = main_world.teams[tonumber(config.team)]
			end
			if not team then
				team = main_world.teams[main_world.spectator_team]
			end
			if table.find(team.players, plr.UserId) then
				warn("player", plr.Name, "is already in team", team.name)
				return
			end
			table.insert(team.players, plr.UserId)
			table.insert(team.historical_players, plr.UserId)
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
			table.insert(team_with_least_players.players, plr.UserId)
			table.insert(team_with_least_players.historical_players, plr.UserId)
		end
		task.defer(function()
			main_world.player_data[tostring(plr.UserId)] = datastore_mod.get_player_data(plr.UserId)
			main_world:add_update {
				type = "player_data",
				player_data = {
					[tostring(plr.UserId)] = main_world.player_data[tostring(plr.UserId)],
				},
			}
			updates_mod.flush_updates(main_world)
		end)
		local team = team_mod.team_of(main_world, plr)
		plr.Team = team_instances[team.id]
	end

	for _, plr in Players:GetPlayers() do
		auto_add_player(plr)
	end

	turn_scheduler.recalculate_skips(main_world)

	Players.PlayerAdded:Connect(function(plr)
		auto_add_player(plr)
		turn_scheduler.recalculate_skips(main_world)
		republish_teams(main_world)
		updates_mod.flush_updates(main_world)
	end)
	Players.PlayerRemoving:Connect(function(plr)
		for _, team in main_world.teams do
			util.table_remove_needle(team.players, plr.UserId)
		end
		util.table_remove_needle(main_world.skipped, plr.UserId)
		local player_data = main_world.player_data[tostring(plr.UserId)]
		datastore_mod.set_player_data(plr.UserId, player_data)
		turn_scheduler.recalculate_skips(main_world)
		republish_teams(main_world)
		updates_mod.flush_updates(main_world)
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
