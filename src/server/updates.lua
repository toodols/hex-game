local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"

local util = require(ReplicatedStorage.Shared.util)
local types = require(ReplicatedStorage.Shared.types)
local team_mod = require(ReplicatedStorage.Shared.team)
local coords_mod = require(ReplicatedStorage.Shared.coords)

local serialize_mod = require(script.Parent.serialize)
local remotes_mod = require(script.Parent.remotes)
local visibility = require(script.Parent.visibility)
local server_types = require(script.Parent.types)

type World = types.World
type WorldUpdate = types.WorldUpdate
type EntityId = types.EntityId
type TeamId = types.TeamId
type TeamData = types.TeamData

type SerializeFor = server_types.SerializeFor
type SerializationContext = server_types.SerializationContext

-- Removes all but the last "entity_update" for each entity_id from a list of updates.
function filter_duplicate_entity_updates(updates)
	local last_occurrences: { [EntityId]: number } = {}
	local result = {}
	for i, update in updates do
		if update.type == "entity_update" then
			last_occurrences[update.entity.id] = i
		end
	end

	for i, update in updates do
		if update.type ~= "entity_update" or last_occurrences[update.entity.id] == i then
			table.insert(result, update)
		end
	end

	return result
end

function get_updates(
	world: World,
	se_ctx: SerializationContext,
	serialize_for: SerializeFor,
	buffer: { WorldUpdate }
): { WorldUpdate }
	local team = if serialize_for.team then world.teams[serialize_for.team] else nil
	if team and #team.players == 0 and not RunService:IsStudio() then
		return {}
	end
	if serialize_for.team ~= nil and team == nil then
		print(world.teams, serialize_for.team)
		error "wtf"
	end
	local mapped = filter_duplicate_entity_updates(util.table_filter_map(buffer, function(update: WorldUpdate)
		local target = (update :: any).target or "everyone"
		if
			serialize_for.team ~= nil
			and team.server_data.visibility ~= "perfect"
			and target ~= "everyone"
			and table.find(target, serialize_for.team) == nil
		then
			return
		end
		if update.type == "entity_update" then
			local serialized = serialize_mod.serialize_entity(world, se_ctx, serialize_for, update.entity)
			return serialized and {
				type = update.type,
				entity = serialized,
			}
		elseif update.type == "entity_created" then
			if visibility.entity_visibility(world, serialize_for, world.entities[update.entity_id]) then
				return {
					type = update.type,
					entity_id = update.entity_id,
				}
			else
				return nil
			end
		elseif update.type == "entity_event" then
			if visibility.entity_visibility(world, serialize_for, world.entities[update.entity_id]) then
				return update
			else
				return nil
			end
		elseif update.type == "cell_update" then
			local serialized =
				serialize_mod.serialize_cell(world, se_ctx, serialize_for, coords_mod.encode_coord(update.coord))
			return serialized and {
				type = update.type,
				entity = serialized,
			}
		elseif update.type == "ability" then
			local hit_cell = world:get_cell(update.coordinate)
			local entity = world.entities[update.entity_id]
			if
				serialize_for.team == nil
				or team_mod.is_allied(world, hit_cell.owner, team.id)
				or team_mod.is_allied(world, entity.owner, serialize_for.team)
			then
				return {
					type = update.type,
					entity_id = update.entity_id,
					ability_type = update.ability_type,
					coordinate = update.coordinate,
				}
			end
			return nil
		elseif update.type == "cells" then
			return {
				type = update.type,
				cells = util.table_map(update.cells, function(cell, coord)
					return serialize_mod.serialize_cell(world, se_ctx, serialize_for, coord)
				end),
			}
		elseif update.type == "world" then
			return {
				type = update.type,
				world = serialize_mod.serialize_world(world, se_ctx, serialize_for),
			}
		elseif update.type == "systems" then
			return {
				type = update.type,
				systems = util.table_filter_map(update.systems, function(system)
					return serialize_mod.serialize_system(world, se_ctx, serialize_for, system)
				end),
			}
		elseif update.type == "player_data" then
			if serialize_for.team == nil then
				return {
					type = update.type,
					player_data = world.player_data,
				}
			end
			if serialize_for.player then
				local player_data = world.player_data[tostring(serialize_for.player)]
				if player_data == nil then
					return nil
				end
				return {
					type = update.type,
					player_data = {
						[tostring(serialize_for.player)] = player_data,
					},
				}
			else
				return nil
			end
		else
			return update
		end
	end))
	return mapped or {}
end

function flush_updates(world: World): { [TeamId]: { WorldUpdate } }
	local buffer = world.updates_buffer
	local updates = {}
	local se_ctx = {}

	for _, player in game.Players:GetPlayers() do
		local player_team = team_mod.team_of_id(world, player.UserId) :: TeamData
		if player_team == nil then
			-- warn(`Player {player.Name} ({player.UserId}) has no team`)
			continue
		end
		local updates_for_player = get_updates(world, se_ctx, { team = player_team.id, player = player.UserId }, buffer)
		remotes_mod.world_updates_remote:FireClient(player, updates_for_player)
	end

	for _, team in world.teams do
		updates[team.id] = get_updates(world, se_ctx, {
			team = team.id,
		}, buffer)
		-- if #updates[team.id] > 0 then
		-- 	for _, user_id in team.players do
		-- 		local player = game.Players:GetPlayerByUserId(user_id)
		-- 		remotes_mod.world_updates_remote:FireClient(player, updates[team.id])
		-- 	end
		-- end
	end
	world.updates_buffer = {}
	return updates
end

return {
	get_updates_for_team = get_updates,
	flush_updates = flush_updates,
}
