local ServerScriptService = game:GetService "ServerScriptService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local HttpService = game:GetService "HttpService"

local types = require(ReplicatedStorage.Shared.types)
local world_mod = require(ReplicatedStorage.Shared.world)
local updates_mod = require(ServerScriptService.Server.updates)
local influences_mod = require(ServerScriptService.Server.influences)
local visibility_mod = require(ServerScriptService.Server.visibility)
local turn_scheduler = require(ServerScriptService.Server.turn_scheduler)
local turn_scheduler_init = require(ServerScriptService.Server.turn_scheduler_init)
local presence_mod = require(ServerScriptService.Server.presence)
local server_entity_mod = require(ServerScriptService.Server.entity)
local datastore_mod = require(ServerScriptService.Server.datastore)
local set_deposit_type = require(ServerScriptService.Server.deposit).set_deposit_type

type World = types.World
type CubicCoordinate = types.CubicCoordinate

function current_world(c: any): World
	local world = _G.world
	if world == nil then
		c.fail "the game hasn't started"
	end
	return world
end

function schedule_of(c: any, world: World): any
	local schedule = world.turn_schedule
	if schedule == nil then
		c.fail "this match has no turn timer"
	end
	return schedule
end

function team_of(c: any, world: World, team_id: number): any
	local team = world.teams[team_id]
	if team == nil then
		c.fail(`there is no team {team_id}`)
	end
	return team
end

function player_data_of(c: any, world: World, player: Player): any
	local player_data = world.player_data[tostring(player.UserId)]
	if player_data == nil then
		c.fail(`{player.Name}'s player data hasn't loaded`)
	end
	return player_data
end

function setup(powder: any)
	powder.namespace("timer", "The turn timer.")
	powder.namespace("team", "Teams: who is on them, what they see, and the AI.")
	powder.namespace("game", "Saving and loading the match, and the match result webhook.")
	powder.namespace("entity", "Spawning and removing entities.")
	powder.namespace("cell", "What cells are and what is under them.")
	powder.namespace("unlockable", "What players have unlocked.")

	powder.command {
		name = "timer.resume",
		description = "Resumes the turn timer.",
		aliases = { "resume_timer" },
		capabilities = { "gamemaster" },
		location = "server",
		params = {},
		run = function(c: any)
			local world = current_world(c)
			turn_scheduler.turn_schedule_resume(schedule_of(c, world))
			turn_scheduler.report_turn_time(world)
			return nil
		end,
	}

	powder.command {
		name = "timer.pause",
		description = "Pauses the turn timer.",
		aliases = { "pause_timer" },
		capabilities = { "gamemaster" },
		location = "server",
		params = {},
		run = function(c: any)
			local world = current_world(c)
			turn_scheduler.turn_schedule_stop(schedule_of(c, world))
			turn_scheduler.report_turn_time(world)
			return nil
		end,
	}

	powder.command {
		name = "timer.skip",
		description = "Ends the current turn now.",
		aliases = { "skip_timer" },
		capabilities = { "gamemaster" },
		location = "server",
		params = {},
		run = function(c: any)
			turn_scheduler.turn_schedule_skip(schedule_of(c, current_world(c)))
			return nil
		end,
	}

	powder.command {
		name = "timer.speed",
		description = "Sets how long turns last: the base, plus the multiplier for every entity.",
		aliases = { "set_game_speed" },
		capabilities = { "gamemaster" },
		location = "server",
		params = {
			{ name = "base", type = "number", description = "Seconds every turn lasts." },
			{ name = "multiplier", type = "number", description = "Seconds added for every entity." },
		},
		run = function(c: any, base: number, multiplier: number)
			local world = current_world(c)
			world.speed_base = base
			world.speed_multiplier = multiplier
			return nil
		end,
	}

	powder.command {
		name = "team.ai",
		description = "Runs the AI for a team, once.",
		aliases = { "run_ai" },
		capabilities = { "gamemaster" },
		location = "server",
		params = { { name = "team", type = "team", description = "The team to run the AI for." } },
		run = function(c: any, team_id: number)
			local world = current_world(c)
			require(ServerScriptService.Server.ai).decide(world, team_of(c, world, team_id), {}, {})
			return nil
		end,
	}

	powder.command {
		name = "team.set",
		description = "Moves players onto a team.",
		aliases = { "set_team" },
		capabilities = { "gamemaster" },
		location = "server",
		params = {
			{ name = "targets", type = "players", description = "The players to move." },
			{ name = "team", type = "team", description = "The team to move them to." },
		},
		run = function(c: any, targets: { Player }, team_id: number)
			local world = current_world(c)
			local new_team = team_of(c, world, team_id)
			local user_ids = {}
			for _, player in targets do
				table.insert(user_ids, player.UserId)
			end
			for _, team in world.teams do
				for _, user_id in user_ids do
					local index = table.find(team.players, user_id)
					if index ~= nil then
						table.remove(team.players, index)
					end
				end
			end
			for _, user_id in user_ids do
				table.insert(new_team.players, user_id)
			end
			world:add_update {
				type = "world",
			}
			updates_mod.flush_updates(world)
			return nil
		end,
	}

	powder.command {
		name = "team.visibility",
		description = "Sets how much of the world a team sees.",
		aliases = { "set_visibility" },
		capabilities = { "gamemaster" },
		location = "server",
		params = {
			{ name = "team", type = "team", description = "The team." },
			{ name = "visibility", type = "visibility", description = "What it sees." },
		},
		run = function(c: any, team_id: number, visibility: string)
			local world = current_world(c)
			team_of(c, world, team_id).server_data.visibility = visibility
			return nil
		end,
	}

	powder.command {
		name = "game.webhook",
		description = "Posts a test message to the match result webhook.",
		aliases = { "test_webhook" },
		capabilities = { "game.admin" },
		location = "server",
		params = {},
		run = function(c: any)
			local webhook = HttpService:GetSecret "MATCH_RESULT_WEBHOOK_URL"
			webhook = webhook:AddPrefix "https://discord.com/api/webhooks/"
			HttpService:PostAsync(
				webhook,
				HttpService:JSONEncode {
					content = "test webhook from powder",
				}
			)
			return nil
		end,
	}

	powder.command {
		name = "game.load",
		description = "Replaces the match with one saved under a key.",
		aliases = { "load_game" },
		capabilities = { "game.admin" },
		location = "server",
		params = { { name = "key", type = "string", description = "The key it was saved under." } },
		run = function(c: any, key: string)
			local world = current_world(c)
			local data = datastore_mod.load_world(key)
			turn_scheduler.turn_schedule_kill(world.turn_schedule)
			world_mod.apply_world_data(world, data)
			turn_scheduler_init.hydrate(world, world.turn_schedule)
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
			return nil
		end,
	}

	powder.command {
		name = "game.save",
		description = "Saves the match under a key.",
		aliases = { "save_game" },
		capabilities = { "game.admin" },
		location = "server",
		params = { { name = "key", type = "string", description = "The key to save it under." } },
		returns = "string",
		run = function(c: any, key: string)
			return datastore_mod.save_world(current_world(c), key)
		end,
	}

	powder.command {
		name = "entity.spawn",
		description = "Spawns an entity on a cell, owned by a team.",
		aliases = { "spawn_entity" },
		capabilities = { "gamemaster" },
		location = "server",
		params = {
			{ name = "entity_type", type = "entity_type", description = "The kind of entity." },
			{ name = "owner", type = "team", description = "The team that owns it." },
			{ name = "coord", type = "coord", description = "Where, e.g. 1,-1 or (selected)." },
		},
		run = function(c: any, entity_type: string, owner: number, coord: CubicCoordinate)
			local world = current_world(c)
			team_of(c, world, owner)
			if world:get_cell(coord) == nil then
				c.fail "there is no cell there"
			end
			server_entity_mod.new_entity({
				type = entity_type,
				primary_coordinate = coord,
				owner = owner,
			}, world)
			updates_mod.flush_updates(world)
			return nil
		end,
	}

	powder.command {
		name = "entity.kill",
		description = "Removes every entity on these cells.",
		capabilities = { "gamemaster" },
		location = "server",
		params = { { name = "coords", type = "coords", description = "The cells, e.g. (selected)." } },
		run = function(c: any, coords: { CubicCoordinate })
			local world = current_world(c)
			for _, coord in coords do
				local cell = world:get_cell(coord)
				if cell == nil then
					continue
				end
				for entity_id in cell.entities do
					local entity = world.entities[entity_id]
					if entity == nil then
						continue
					end
					world:add_update {
						type = "entity_event",
						event_type = "destroy",
						entity_id = entity.id,
						death_type = "other",
					}
					server_entity_mod.remove_entity(world, entity)
				end
			end
			updates_mod.flush_updates(world)
			world_mod.purge_destroyed_entities(world)
			return nil
		end,
	}

	powder.command {
		name = "cell.deposit",
		description = "Sets the deposit under cells.",
		aliases = { "set_deposit_type" },
		capabilities = { "gamemaster" },
		location = "server",
		params = {
			{ name = "deposit_type", type = "deposit_type", description = "The kind of deposit." },
			{ name = "coords", type = "coords", description = "The cells, e.g. (selected)." },
		},
		run = function(c: any, deposit_type: string, coords: { CubicCoordinate })
			local world = current_world(c)
			for _, coord in coords do
				if world:get_cell(coord) ~= nil then
					set_deposit_type(world, coord, deposit_type)
				end
			end
			updates_mod.flush_updates(world)
			return nil
		end,
	}

	powder.command {
		name = "cell.type",
		description = "Sets what kind of cell cells are.",
		aliases = { "set_cell_type" },
		capabilities = { "gamemaster" },
		location = "server",
		params = {
			{ name = "cell_type", type = "cell_type", description = "The kind of cell." },
			{ name = "coords", type = "coords", description = "The cells, e.g. (selected)." },
		},
		run = function(c: any, cell_type: string, coords: { CubicCoordinate })
			local world = current_world(c)
			for _, coord in coords do
				local cell = world:get_cell(coord)
				if cell ~= nil then
					cell.type = cell_type
				end
			end
			return nil
		end,
	}

	powder.command {
		name = "data.reset",
		description = "Resets players' data to a new player's.",
		aliases = { "reset_player_data" },
		capabilities = { "game.admin" },
		location = "server",
		params = { { name = "targets", type = "players", description = "Whose data to reset." } },
		run = function(c: any, targets: { Player })
			local world = current_world(c)
			for _, player in targets do
				local player_data = datastore_mod.default_player_data()
				world.player_data[tostring(player.UserId)] = player_data
				datastore_mod.set_player_data(player.UserId, player_data)
				world:add_update {
					type = "player_data",
					player_data = { [tostring(player.UserId)] = player_data },
				}
			end
			updates_mod.flush_updates(world)
			return nil
		end,
	}

	powder.command {
		name = "unlockable.add",
		description = "Gives players an unlockable.",
		aliases = { "add_unlockable" },
		capabilities = { "game.admin" },
		location = "server",
		params = {
			{ name = "targets", type = "players", description = "Who gets it." },
			{ name = "unlockable", type = "unlockable", description = "The unlockable." },
		},
		run = function(c: any, targets: { Player }, unlockable: string)
			local world = current_world(c)
			for _, player in targets do
				local player_data = player_data_of(c, world, player)
				player_data.unlockables_owned[unlockable] = true
				world:add_update {
					type = "player_data",
					player_data = { [tostring(player.UserId)] = player_data },
				}
			end
			updates_mod.flush_updates(world)
			return nil
		end,
	}

	powder.command {
		name = "unlockable.remove",
		description = "Takes an unlockable away from players.",
		aliases = { "remove_unlockable" },
		capabilities = { "game.admin" },
		location = "server",
		params = {
			{ name = "targets", type = "players", description = "Who loses it." },
			{ name = "unlockable", type = "unlockable", description = "The unlockable." },
		},
		run = function(c: any, targets: { Player }, unlockable: string)
			local world = current_world(c)
			for _, player in targets do
				local player_data = player_data_of(c, world, player)
				player_data.unlockables_owned[unlockable] = nil
				world:add_update {
					type = "player_data",
					player_data = { [tostring(player.UserId)] = player_data },
				}
			end
			updates_mod.flush_updates(world)
			return nil
		end,
	}
end

return {
	name = "hex.server",
	setup = setup,
}
