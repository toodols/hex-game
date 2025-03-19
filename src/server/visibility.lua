local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local team_mod = require(ReplicatedStorage.Shared.team)
type TeamId = types.TeamId
type Entity = types.Entity
type HexCell = types.HexCell
type World = types.World
type CellTeamVisibility = types.CellTeamVisibility

-- CellTeamVisibility is server only but this function is a dependency of line_of_sight.blocked which is shared
function cell_visibility(visibility: CellTeamVisibility?)
	return visibility and (visibility.contact or visibility.fogless or visibility.portal or visibility.illumination)
end

function entity_visibility(world: World, entity: Entity, team: TeamId): boolean
	if entity.server_data.always_visible then
		return true
	end
	if team_mod.is_allied(world, entity.owner, team) then
		return true
	end
	if entity.server_data.is_disguise_of ~= nil then
		local cell = world:get_cell(entity.primary_coordinate)
		if cell and cell_visibility(cell.server_data.visibility[team]) then
			return true
		end
		return false
	end

	local cell = world:get_cell(entity.primary_coordinate)
	if
		cell_visibility(cell.server_data.visibility[team])
		and entity.status ~= "blueprint"
		and entity.active
		and entity.disguise == nil
	then
		return true
	end
	return false
end

return {
	cell_visibility = cell_visibility,
	entity_visibility = entity_visibility,
}
