local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"

local util = require(ReplicatedStorage.Shared.util)
local types = require(ReplicatedStorage.Shared.types)
local team_mod = require(ReplicatedStorage.Shared.team)
local coords_mod = require(ReplicatedStorage.Shared.coords)
local serializing = require(ReplicatedStorage.Shared.serializing)

local view_mod = require(script.Parent.view)
local remotes_mod = require(script.Parent.remotes)
local visibility = require(script.Parent.visibility)
local server_types = require(script.Parent.types)

type World = types.World
type WorldUpdate = types.WorldUpdate
type EntityId = types.EntityId
type TeamId = types.TeamId
type TeamData = types.TeamData

type ViewTarget = server_types.ViewTarget
type ViewContext = server_types.ViewContext

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
	view_ctx: ViewContext,
	view_target: ViewTarget,
	buffer: { WorldUpdate }
): { WorldUpdate }
	local team = if view_target.team then world.teams[view_target.team] else nil
	if team and #team.players == 0 and not RunService:IsStudio() then
		return {}
	end
	if view_target.team ~= nil and team == nil then
		warn(world.teams, view_target.team)
		error "^ wtf"
	end
	local mapped = filter_duplicate_entity_updates(util.table_filter_map(buffer, function(update: WorldUpdate)
		local target = (update :: any).target or "everyone"
		if
			view_target.team ~= nil
			and team.server_data.visibility ~= "perfect"
			and target ~= "everyone"
			and table.find(target, view_target.team) == nil
		then
			return
		end
		if update.type == "entity_update" then
			local view = view_mod.entity_view(world, view_ctx, view_target, update.entity)
			return view and {
				type = update.type,
				entity = view,
			}
		elseif update.type == "entity_created" then
			if visibility.entity_visibility(world, view_target, world.entities[update.entity_id]) then
				return {
					type = update.type,
					entity_id = update.entity_id,
				}
			else
				return nil
			end
		elseif update.type == "entity_event" then
			if visibility.entity_visibility(world, view_target, world.entities[update.entity_id]) then
				return update
			else
				return nil
			end
		elseif update.type == "cell_update" then
			local view = view_mod.cell_view(world, view_ctx, view_target, coords_mod.encode_coord(update.coord))
			return view and {
				type = update.type,
				entity = view,
			}
		elseif update.type == "ability" then
			local hit_cell = world:get_cell(update.coordinate)
			local entity = world.entities[update.entity_id]
			if
				view_target.team == nil
				or team_mod.is_allied(world, hit_cell.owner, team.id)
				or team_mod.is_allied(world, entity.owner, view_target.team)
			then
				return {
					type = update.type,
					entity_id = update.entity_id,
					ability_id = update.ability_id,
					coordinate = update.coordinate,
				}
			end
			return nil
		elseif update.type == "cells" then
			return {
				type = update.type,
				cells = util.table_map(update.cells, function(cell, coord)
					return view_mod.cell_view(world, view_ctx, view_target, coord)
				end),
			}
		elseif update.type == "world" then
			return {
				type = update.type,
				world = view_mod.world_view(world, view_ctx, view_target),
			}
		elseif update.type == "systems" then
			return {
				type = update.type,
				systems = util.table_filter_map(update.systems, function(system)
					return view_mod.system_view(world, view_ctx, view_target, system)
				end),
			}
		elseif update.type == "player_data" then
			if view_target.team == nil then
				return {
					type = update.type,
					player_data = world.player_data,
				}
			end
			if view_target.player then
				local player_data = world.player_data[tostring(view_target.player)]
				if player_data == nil then
					return nil
				end
				return {
					type = update.type,
					player_data = {
						[tostring(view_target.player)] = player_data,
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

function serialize_updates_safely(updates: { WorldUpdate }): string
	local success, serialized = pcall(serializing.serialize_world_updates, updates)
	if success then
		return serialized
	end
	warn("Failed to serialize updates, dropping the ones that fail:", serialized)
	local valid = {}
	for _, update in updates do
		local update_success, update_err = pcall(serializing.serialize_world_updates, { update })
		if update_success then
			table.insert(valid, update)
		else
			warn(`Dropped "{update.type}" update:`, update_err)
		end
	end
	return serializing.serialize_world_updates(valid)
end

function flush_updates(world: World): { [TeamId]: { WorldUpdate } }
	local buffer = world.updates_buffer
	world.updates_buffer = {}
	local updates = {}
	local view_ctx = {}

	for _, player in game.Players:GetPlayers() do
		local player_team = team_mod.team_of_id(world, player.UserId) :: TeamData
		if player_team == nil then
			-- warn(`Player {player.Name} ({player.UserId}) has no team`)
			continue
		end
		local success, err = pcall(function()
			local updates_for_player =
				get_updates(world, view_ctx, { team = player_team.id, player = player.UserId }, buffer)
			remotes_mod.world_updates_remote:FireClient(player, serialize_updates_safely(updates_for_player))
		end)
		if not success then
			warn(`Failed to send updates to {player.Name}:`, err)
		end
	end

	for _, team in world.teams do
		updates[team.id] = get_updates(world, view_ctx, {
			team = team.id,
		}, buffer)
		-- if #updates[team.id] > 0 then
		-- 	for _, user_id in team.players do
		-- 		local player = game.Players:GetPlayerByUserId(user_id)
		-- 		remotes_mod.world_updates_remote:FireClient(player, updates[team.id])
		-- 	end
		-- end
	end
	return updates
end

return {
	get_updates_for_team = get_updates,
	flush_updates = flush_updates,
}
