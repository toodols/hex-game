local ReplicatedStorage = game:GetService "ReplicatedStorage"
local HttpService = game:GetService "HttpService"
local Players = game:GetService "Players"
local TeleportService = game:GetService "TeleportService"
local RunService = game:GetService "RunService"

local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local placeids = require(ReplicatedStorage.Shared.placeids).placeids

type Room = types.Room

local START_TIME = if RunService:IsStudio() then 5 else 10
local REQUIRES_FILLED_TEAMS = if RunService:IsStudio() then true else true

local rooms_remote = Instance.new "RemoteEvent"
rooms_remote.Name = "Rooms"
rooms_remote.Parent = ReplicatedStorage

local maps = {
	my_map = {
		teams = {
			["2"] = {
				color = Color3.fromRGB(97, 97, 97),
				name = "Spectator",
				is_spectator_team = true,
			},
			["3"] = {
				color = Color3.fromRGB(255, 49, 49),
				name = "Red",
			},
			["4"] = {
				color = Color3.fromRGB(48, 48, 255),
				name = "Blue",
			},
		},
	},
	tutorial_map = {
		teams = {
			["3"] = {
				color = Color3.fromRGB(255, 49, 49),
				name = "Red",
			},
		},
	},
}

local rooms: { [string]: Room } = {}

-- while wait loop not elegant
local room_timers: { [string]: { stop: () -> (), reset: () -> () } } = {}

function room_membership_changed(room: Room)
	if next(room.players) == nil then
		rooms[room.id] = nil
		if room_timers[room.id] then
			room_timers[room.id].stop()
			room_timers[room.id] = nil
		end
	else
		if
			not REQUIRES_FILLED_TEAMS
			or util.table_every(room.teams, function(team, idx)
				local v = team.is_spectator_team
					or util.table_any(room.players, function(player)
						return player.team == idx
					end)
				return v
			end)
		then
			room.starting_at = workspace:GetServerTimeNow() + START_TIME
			room_timers[room.id] = util.timer(START_TIME, function()
				local party = {}
				for player_id, data in room.players do
					local player = Players:GetPlayerByUserId(player_id)
					assert(player, "Player not found")
					table.insert(party, player)
				end

				local teleport_options = Instance.new "TeleportOptions"
				-- what if we signed the data to make it tamper proof
				teleport_options:SetTeleportData {
					room = room,
				}
				local code = TeleportService:ReserveServer(placeids.game)
				TeleportService:TeleportToPrivateServer(placeids.game, code, party, nil, teleport_options)
			end)
		else
			if room_timers[room.id] then
				room_timers[room.id].stop()
				room_timers[room.id] = nil
				room.starting_at = nil
			end
		end
		rooms_remote:FireAllClients {
			rooms = rooms,
		}
	end
end

type Props = {
	type: "join_room",
	room_id: string,
} | {
	type: "leave_room",
} | {
	type: "new_room",
	-- max players in this room
	max_players: number,
	-- Teams can have at most 1 more member than every other team
	balanced_teams: boolean,
	friends_only: boolean,
	map_type: "my_map" | "tutorial_map",
} | {
	type: "set_team",
	player: Player?,
	team: number,
} | {
	type: "get_rooms",
}

rooms_remote.OnServerEvent:Connect(function(plr: Player, props: Props)
	if props.type == "new_room" then
		for _, room in rooms do
			if room.players[tostring(plr.UserId)] ~= nil then
				room.players[tostring(plr.UserId)] = nil
				room_membership_changed(room)
			end
		end
		props.map_type = props.map_type or "my_map"
		local room: Room = {
			teams = maps[props.map_type].teams,
			id = HttpService:GenerateGUID(false),
			players = {},
			map = props.map_type,
		}
		room.players[tostring(plr.UserId)] = {
			team = "3",
		}
		rooms[room.id] = room
		room_membership_changed(room)
		rooms_remote:FireAllClients {
			rooms = rooms,
		}
	elseif props.type == "join_room" then
		if props.room_id and rooms[props.room_id] and rooms[props.room_id].players[tostring(plr.UserId)] == nil then
			for _, room in rooms do
				if room.players[tostring(plr.UserId)] ~= nil then
					room.players[tostring(plr.UserId)] = nil
					room_membership_changed(room)
				end
			end
			rooms[props.room_id].players[tostring(plr.UserId)] = {
				team = "3",
			}
			rooms_remote:FireAllClients {
				rooms = rooms,
			}
		end
	elseif props.type == "leave_room" then
		for _, room in rooms do
			if room.players[tostring(plr.UserId)] ~= nil then
				room.players[tostring(plr.UserId)] = nil

				room_membership_changed(room)
				rooms_remote:FireAllClients {
					rooms = rooms,
				}
				break
			end
		end
	elseif props.type == "set_team" then
		local room = util.table_find_pred(rooms, function(room_)
			return room_.players[tostring(plr.UserId)] ~= nil
		end)
		if room and room.teams[props.team] ~= nil then
			room.players[tostring(plr.UserId)].team = props.team
			room_membership_changed(room)
			rooms_remote:FireAllClients {
				rooms = rooms,
			}
		end
	elseif props.type == "get_rooms" then
		rooms_remote:FireClient(plr, {
			rooms = rooms,
		})
	end
end)

task.spawn(function()
	while true do
		task.wait(5)
		-- get ongoing servers
	end
end)

Players.PlayerAdded:Connect(function(plr)
	local join_data = plr:GetJoinData()
	print(join_data)
end)

Players.PlayerRemoving:Connect(function(plr: Player)
	for id, room in rooms do
		if room.players[tostring(plr.UserId)] ~= nil then
			room.players[tostring(plr.UserId)] = nil
			room_membership_changed(room)
		end
	end
	rooms_remote:FireAllClients {
		rooms = rooms,
	}
end)
