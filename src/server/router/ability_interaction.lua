local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local server_types = require(ServerScriptService.Server.types)
local coords_mod = require(ReplicatedStorage.Shared.coords)
local ability_mod = require(ReplicatedStorage.Shared.ability)

type World = types.World
type Interaction = types.Interaction
type PlayerInfo = server_types.PlayerInfo
type EntityId = types.EntityId

function ability_interaction(world: World, entry: Interaction, player_info: PlayerInfo): { [EntityId]: boolean }
	assert(entry.type == "ability", "Expected entry to be an ability interaction")
	local entity = world.entities[entry.entity_id]
	if not entity or not entity.active or entity.owner ~= player_info.team or entity.status ~= "complete" then
		-- error_type.mistake
		return {}
	end
	local entity_config = world.entity_configurations[entity.type]
	local ability = entity_config.abilities[entry.ability_id]
	if ability == nil then
		-- not a valid ability of this entity
		return {}
	end

	if ability.type == "cannon" or ability.type == "rash" then
		local candidates =
			ability_mod.entity_attack_candidates(world, entity, ability.range, player_info.team, ability.ignore_los)

		if candidates[coords_mod.encode_coord(entry.coordinate)] == nil then
			return {}
		end
	elseif ability.type == "disguise" then
		local cell = world:get_cell(entry.coordinate)
		if cell == nil then
			return {}
		end
	elseif ability.type == "solution_activate" or ability.type == "impression_activate" then
		--ok
	end

	util.table_extract(entity.queued_decisions, function(decision)
		return decision.type == "ability" and decision.ability_id == entry.ability_id
	end)
	table.insert(entity.queued_decisions, entry)
	return { [entity.id] = true }
end

return {
	ability_interaction = ability_interaction,
}
