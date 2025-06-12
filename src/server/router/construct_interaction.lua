local ServerScriptService = game:GetService "ServerScriptService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local unlockable_mod = require(ReplicatedStorage.Shared.unlockable)

local server_types = require(ServerScriptService.Server.types)
local presence_mod = require(ServerScriptService.Server.presence)
local entity_mod = require(ServerScriptService.Server.entity)
local server_entity_mod = require(ServerScriptService.Server.entity)

type World = types.World
type Interaction = types.Interaction
type PlayerInfo = server_types.PlayerInfo
type EntityId = types.EntityId

function construct_interaction(world: World, entry: Interaction, player_info: PlayerInfo): { [EntityId]: boolean }
	assert(entry.type == "construct", "Expected entry to be a construct interaction")

	local entity_config = world.entity_configurations[entry.entity_type]
	if entity_config == nil then
		warn("Entity configuration not found for entity type: ", entry.entity_type)
		return {}
	end

	-- the cell exists
	local cell = world:get_cell(entry.coordinate)
	if not cell then
		return {}
	end

	if not presence_mod.team_may_naively_place_blueprint(world, player_info.team, entry.coordinate) then
		return {}
	end

	if player_info.player then
		local player_data = world.player_data[tostring(player_info.player.UserId)]
		if unlockable_mod.player_has_unlockable(player_data, entity_config.required_unlockable) == false then
			return {}
		end
	end

	-- and is not blocked
	if
		util.table_any(
			util.table_map(cell.entities, function(_, id)
				return world.entities[id]
			end),
			function(entity)
				if entity.owner == player_info.team then
					return world.entity_configurations[entity.type].layer == entity_config.layer
				end
				return nil
			end
		)
	then
		return {}
	end

	-- and the entity is allowed to be built on the cell
	local server_behavior = server_entity_mod.registry[entry.entity_type]
	if #server_behavior.built_on > 0 then
		if not table.find(server_behavior.built_on, cell.type) then
			return {}
		end
	end

	-- and can be built by the player
	if not entity_config.buildable then
		return {}
	end

	local entity = entity_mod.new_entity({
		type = entry.entity_type,
		owner = player_info.team,
		rotation = entry.rotation,
		primary_coordinate = entry.coordinate,
		status = "blueprint",
	}, world)
	return { [entity.id] = true }
end

return {
	construct_interaction = construct_interaction,
}
