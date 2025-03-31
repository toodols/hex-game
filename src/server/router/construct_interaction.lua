local ServerScriptService = game:GetService "ServerScriptService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)

local server_types = require(ServerScriptService.Server.types)
local cell_visibility = require(ServerScriptService.Server.visibility).cell_visibility
local server_entity_mod = require(ServerScriptService.Server.entity)

type World = types.World
type Interaction = types.Interaction
type PlayerInfo = server_types.PlayerInfo
type EntityId = types.EntityId
function construct_interaction(world: World, entry: Interaction, player_info: PlayerInfo): { [EntityId]: boolean }
	assert(entry.type == "construct", "Expected entry to be a construct interaction")
	-- the cell exists
	local cell = world:get_cell(entry.coordinate)
	if not cell then
		return {}
	end

	-- and does not have the presence of an enemy
	local has_enemy_presence = false
	if cell.owner ~= player_info.team then
		for team_id, presence in cell.server_data.presence do
			if team_id ~= player_info.team and presence then
				has_enemy_presence = true
				break
			end
		end
		if has_enemy_presence then
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
					return world.entity_configurations[entity.type].layer
						== world.entity_configurations[entry.entity_type].layer
				end
				return nil
			end
		)
	then
		return {}
	end

	-- and is visible to the player team
	if not cell_visibility(cell.server_data.visibility[player_info.team]) then
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
	local entity_config = world.entity_configurations[entry.entity_type]
	if not entity_config.buildable then
		return {}
	end

	local entity = server_entity_mod.new_entity({
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
