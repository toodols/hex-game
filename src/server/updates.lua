local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"

local util = require(ReplicatedStorage.Shared.util)
local types = require(ReplicatedStorage.Shared.types)
local team_mod = require(ReplicatedStorage.Shared.team)

local serialize_mod = require(script.Parent.serialize)
local remotes_mod = require(script.Parent.remotes)
local visibility = require(script.Parent.visibility)

type World = types.World
type WorldUpdate = types.WorldUpdate
type EntityId = types.EntityId
type TeamId = types.TeamId
type TeamData = types.TeamData

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

function get_updates_for_team(world: World, buffer: { WorldUpdate }, team_id: TeamId): { WorldUpdate }
	local team = world.teams[team_id]
	if #team.players == 0 and not RunService:IsStudio() then
		return {}
	end
	local mapped = filter_duplicate_entity_updates(util.table_filter_map(buffer, function(update: WorldUpdate)
		local target = (update :: any).target or "everyone"
		if team.server_data.visibility ~= "perfect" and target ~= "everyone" and table.find(target, team.id) == nil then
			return
		end
		if update.type == "entity_update" then
			local serialized = serialize_mod.serialize_entity_for_team(world, update.entity, team.id)
			return serialized and {
				type = update.type,
				entity = serialized,
			}
		elseif update.type == "entity_created" then
			if visibility.entity_visibility(world, world.entities[update.entity_id], team.id) then
				return {
					type = update.type,
					entity_id = update.entity_id,
				}
			else
				return nil
			end
		elseif update.type == "entity_event" then
			if visibility.entity_visibility(world, world.entities[update.entity_id], team.id) then
				return update
			else
				return nil
			end
		elseif update.type == "cell_update" then
			local serialized = serialize_mod.serialize_cell_for_team(world, update.cell, team.id)
			return serialized and {
				type = update.type,
				entity = serialized,
			}
		elseif update.type == "ability" then
			local hit_cell = world:get_cell(update.coordinate)
			local entity = world.entities[update.entity_id]
			if
				team_mod.is_allied(world, hit_cell.owner, team.id) or team_mod.is_allied(world, entity.owner, team_id)
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
				cells = util.table_map(update.cells, function(cell)
					return serialize_mod.serialize_cell_for_team(world, cell, team.id)
				end),
			}
		else
			return update
		end
	end))
	return mapped or {}
end

function flush_updates(world: World): { [TeamId]: { WorldUpdate } }
	local buffer = world.updates_buffer
	local updates = {}
	for _, team in world.teams do
		updates[team.id] = get_updates_for_team(world, buffer, team.id)
		if #updates[team.id] > 0 then
			for _, user_id in team.players do
				local player = game.Players:GetPlayerByUserId(user_id)
				remotes_mod.world_updates_remote:FireClient(player, updates[team.id])
			end
		end
	end
	world.updates_buffer = {}
	return updates
end

function add_update(world: World, event: WorldUpdate)
	if event.type == "entity_update" then
		if event.entity == nil then
			error "event.entity is nil"
		end
	end
	table.insert(world.updates_buffer, event)
end

return {
	get_updates_for_team = get_updates_for_team,
	flush_updates = flush_updates,
	add_update = add_update,
}
