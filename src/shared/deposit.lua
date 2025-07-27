local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
type World = types.World
type HexCell = types.HexCell
type CubicCoordinate = types.CubicCoordinate
type DepositType = types.DepositType

function get_deposit_type(world: World, coord: CubicCoordinate): DepositType?
	local cell = world:get_cell(coord) :: HexCell
	for entity_id in cell.entities do
		local entity = world.entities[entity_id]
		if entity.type == "deposit" then
			return entity.deposit_type
		end
	end
	return nil
end

return {
	get_deposit_type = get_deposit_type,
}
