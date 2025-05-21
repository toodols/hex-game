local ServerScriptService = game:GetService "ServerScriptService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local DataStoreService = game:GetService "DataStoreService"

local util = require(ReplicatedStorage.Shared.util)
local archive = require(ServerScriptService.Server.archive)
local base64 = require(ReplicatedStorage.Shared.base64)
local updates_mod = require(ServerScriptService.Server.updates)
local influences_mod = require(ServerScriptService.Server.influences)
local visibility_mod = require(ServerScriptService.Server.visibility)
local turn_scheduler = require(ServerScriptService.Server.turn_scheduler)
local presence_mod = require(ServerScriptService.Server.presence)
local world_mod = require(ReplicatedStorage.Shared.world)
local server_entity_mod = require(ServerScriptService.Server.entity)

return function(extras)
	local commands = extras.commands
	commands.resume_timer = {
		description = "Resumes the timer.",
		permissions = { "admin" },
		overloads = {
			{ returns = "nil", args = {} },
		},
		server_run = function(context)
			local world = _G.world

			turn_scheduler.turn_schedule_resume(world.turn_schedule)
			turn_scheduler.report_turn_time(world)
		end,
	}

	commands.skip_timer = {
		description = "Skips the timer.",
		permissions = { "admin" },
		overloads = {
			{ returns = "nil", args = {} },
		},
		server_run = function(context)
			local world = _G.world
			turn_scheduler.turn_schedule_skip(world.turn_schedule)
		end,
	}

	commands.pause_timer = {
		description = "Pauses the timer.",
		permissions = { "admin" },
		overloads = {
			{ returns = "nil", args = {} },
		},
		server_run = function(context)
			local world = _G.world
			turn_scheduler.turn_schedule_stop(world.turn_schedule)
			turn_scheduler.report_turn_time(world)
		end,
	}

	commands.set_game_speed = {
		description = "Sets the game speed.",
		permissions = { "admin" },
		overloads = {
			{
				returns = "nil",
				args = {
					{
						name = "Speed Base",
						type = "number",
						description = "The speed base in seconds",
					},
					{
						name = "Speed Multiplier",
						type = "number",
						description = "The speed multiplier (second * num_entities).",
					},
				},
			},
		},
		server_run = function(context)
			local world = _G.world
			local speed_base = context.args[1]
			local speed_multiplier = context.args[2]
			world.speed_base = speed_base
			world.speed_multiplier = speed_multiplier
		end,
	}
	commands.set_team = {
		description = "Sets the team of players",
		permissions = { "admin" },
		overloads = {
			{
				returns = "nil",
				args = {
					{
						name = "Players",
						type = "players",
						description = "The player to set the team for.",
					},
					{
						name = "team",
						type = "team",
						description = "The new team.",
					},
				},
			},
		},
		server_run = function(context)
			local targets: { number } = util.table_map(context.args[1], function(player)
				return player.UserId
			end)
			local new_team = _G.world.teams[context.args[2]]
			-- remove all players' userids from world.teams
			for _, team in _G.world.teams do
				team.players = util.table_filter(team.players, function(user_id)
					return not table.find(targets, user_id)
				end)
			end
			for _, user_id in targets do
				table.insert(new_team.players, user_id)
			end
			_G.world:add_update {
				type = "world",
			}
			updates_mod.flush_updates(_G.world)
		end,
	}

	commands.load = {
		description = "Loads the world from a key",
		permissions = { "admin" },
		overloads = {
			{
				returns = "nil",
				args = {
					{
						name = "key",
						type = "string",
						description = "The key to load the world from.",
					},
				},
			},
		},
		server_run = function(context)
			local key = context.args[1]
			local data = archive.deserialize_world(base64.decode(DataStoreService:GetDataStore("saves"):GetAsync(key)))
			local world = _G.world
			turn_scheduler.turn_schedule_kill(world.turn_schedule)
			world_mod.apply_world_data(world, data)
			turn_scheduler.hydrate(world, world.turn_schedule)
			if world.turn_schedule.running then
				turn_scheduler.turn_schedule_resume(world.turn_schedule)
			end
			turn_scheduler.recalculate_skips(world)
			influences_mod.compute_influences(world)
			presence_mod.compute_presence(world)
			visibility_mod.compute_visibility(world)
			world:add_update {
				type = "world",
			}
			updates_mod.flush_updates(world)
		end,
	}

	commands.save = {
		description = "Saves the world in a key",
		permissions = { "admin" },
		overloads = {
			{
				returns = "nil",
				args = {
					{
						name = "key",
						type = "string",
						description = "The key to save the world under.",
					},
				},
			},
		},
		server_run = function(context)
			local world = _G.world
			local key = context.args[1]
			local data = base64.encode(archive.serialize_world(world))
			DataStoreService:GetDataStore("saves"):SetAsync(key, data)
			return data:len() .. " bytes"
		end,
	}

	commands.debug_world = {
		description = "Prints the world",
		permissions = { "admin" },
		overloads = { { returns = "nil", args = {} } },
		server_run = function(context)
			local world = _G.world
			print(world)
		end,
	}

	commands.spawn_entity = {
		description = "spawn_entity",
		permissions = { "admin" },
		overloads = {
			{
				returns = "nil",
				args = {

					{
						name = "entity_type",
						type = "entity_type",
						description = "The type of entity to spawn.",
					},
					{
						name = "owner",
						type = "team",
						description = "The team that owns the entity.",
					},
					{
						name = "coord",
						type = "coord",
						description = "The coordinate of the entity.",
					},
				},
			},
			{
				returns = "nil",
				args = {

					{
						name = "entity_type",
						type = "entity_type",
						description = "The type of entity to spawn.",
					},
					{
						name = "owner",
						type = "team",
						description = "The team that owns the entity.",
					},
				},
			},
		},
		server_run = function(context)
			local world = _G.world
			local entity_type = context.args[1]
			local team = context.args[2]
			local coord = context.args[3] or context.runtime.run_commands_string(context.process, "selected").ok[1]

			server_entity_mod.new_entity({
				type = entity_type,
				primary_coordinate = coord,
				owner = team,
			}, world)
		end,
	}

	commands.set_visibility = {
		description = "Sets the visibility of a team.",
		permissions = { "admin" },
		overloads = {
			{
				returns = "nil",
				args = {
					{
						name = "team",
						type = "team",
						description = "The team to set the visibility for.",
					},
					{
						name = "visibility",
						type = "visibility",
						description = "The new visibility.",
					},
				},
			},
		},
		server_run = function(context)
			local world = _G.world
			local team_id = context.args[1]
			local visibility = context.args[2]
			local team = world.teams[team_id]
			team.server_data.visibility = visibility
		end,
	}
end
