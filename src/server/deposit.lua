local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local server_entity_mod = require(ServerScriptService.Server.entity)

type Entity = types.Entity
type World = types.World
type HexCell = types.HexCell
type DepositType = types.DepositType
type CubicCoordinate = types.CubicCoordinate

function set_deposit_type(world: World, coord: CubicCoordinate, deposit_type: DepositType)
	local cell = world:get_cell(coord)
	assert(cell, "Cell does not found")
	local deposit_entity
	for entity_id in cell.entities do
		local entity = world.entities[entity_id]
		if entity.type == "deposit" then
			deposit_entity = entity
			break
		end
	end
	if deposit_type == nil then
		if deposit_entity then
			server_entity_mod.remove_entity(world, deposit_entity)
		end
		return
	end
	if deposit_entity == nil then
		deposit_entity = server_entity_mod.new_entity({
			type = "deposit",
			primary_coordinate = cell.coordinate,
			owner = world.neutral_team,
		}, world)
	end

	deposit_entity.deposit_type = deposit_type
end

return {
	set_deposit_type = set_deposit_type,
}
