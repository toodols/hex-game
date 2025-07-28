local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
type World = types.World
type HexCell = types.HexCell
type CubicCoordinate = types.CubicCoordinate
type DepositType = types.DepositType
local colored_item_names = require(ReplicatedStorage.Shared.items).colored_item_names

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
	deposit_names = {
		bar_deposit = `{colored_item_names.bar} Deposit`,
		rad_deposit = `{colored_item_names.rad} Deposit`,
		vit_deposit = `{colored_item_names.vit} Deposit`,
		tar_deposit = `{colored_item_names.tar} Deposit`,
	},
	deposit_types = {
		"bar_deposit",
		"rad_deposit",
		"vit_deposit",
		"tar_deposit",
	},
	get_deposit_type = get_deposit_type,
}
