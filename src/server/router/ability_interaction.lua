local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local server_types = require(ServerScriptService.Server.types)
local world_mod = require(ReplicatedStorage.Shared.world)
local coords = require(ReplicatedStorage.Shared.coords)

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
	local ability = entity_config.abilities[entry.ability_type]
	if not ability then
		return {}
	end
	if entry.ability_type == "scout_attack" or entry.ability_type == "turret_attack" then
		local cell = world:get_cell(entry.coordinate)
		if not cell then
			return {}
		end
		local in_range = coords.coords_dist(entity.primary_coordinate, entry.coordinate) <= ability.range
			and world_mod.line_of_sight(world, entity.primary_coordinate, entry.coordinate, player_info.team)
		if not in_range then
			return {}
		end
		-- prevent cells with influence from taunt from being targeted
		for influence in cell.influences do
			if world.entities[influence].type == "taunt" then
				continue
			end
		end
	elseif entry.ability_type == "solution_use" then
		--ok
	end
	util.table_extract(entity.queued_decisions, function(decision)
		return decision.type == "ability" and decision.ability_type == entry.ability_type
	end)
	table.insert(entity.queued_decisions, entry)
	return { [entity.id] = true }
end

return {
	ability_interaction = ability_interaction,
}
