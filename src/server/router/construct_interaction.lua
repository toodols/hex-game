local ServerScriptService = game:GetService "ServerScriptService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local types = require(ReplicatedStorage.Shared.types)
local unlockable_mod = require(ReplicatedStorage.Shared.unlockable)
local construction_condition_mod = require(ReplicatedStorage.Shared.construction_condition)
local validate_condition = construction_condition_mod.validate_condition
local cell_blocked = construction_condition_mod.cell_blocked
local coords = require(ReplicatedStorage.Shared.coords)

local server_types = require(ServerScriptService.Server.types)
local presence_mod = require(ServerScriptService.Server.presence)
local entity_mod = require(ServerScriptService.Server.entity)

type World = types.World
type Interaction = types.Interaction
type PlayerInfo = server_types.PlayerInfo
type EntityId = types.EntityId
type HexCell = types.HexCell
type TeamId = types.TeamId
type CubicCoordinate = types.CubicCoordinate

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
		if not unlockable_mod.player_has_unlockable(player_data, entity_config.required_unlockable) then
			return {}
		end
	end

	-- and is not blocked
	if cell_blocked(world, cell.coordinate, player_info.team, entry.entity_type) then
		return {}
	end

	-- and can be built by the player
	if not entity_config.buildable then
		return {}
	end

	local coordinates = {}
	for _, offset in entity_config.offsets do
		table.insert(coordinates, coords.coords_add(entry.coordinate, offset))
	end

	if world.global_configuration.construction_condition_enabled then
		local ok = validate_condition(world, coordinates, player_info.team, entity_config.construction_condition, true)
		if not ok then
			return {}
		end
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
