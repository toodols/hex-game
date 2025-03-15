local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
type TeamId = types.TeamId
type Entity = types.Entity
type HexCell = types.HexCell
type CellTeamVisibility = types.CellTeamVisibility

-- this is server only but is also depended on line_of_sight.blocked which is a shared function
function cell_visibility(visibility: CellTeamVisibility?)
	return visibility and (visibility.contact or visibility.fogless or visibility.portal)
end

function entity_visibility(entity: Entity, cell: HexCell, team: TeamId): boolean
	return cell_visibility(cell.server_data.visibility[team])
		or entity.server_data.always_visible and (entity.owner == team or entity.status ~= "blueprint")
end

return {
	cell_visibility = cell_visibility,
	entity_visibility = entity_visibility,
}
