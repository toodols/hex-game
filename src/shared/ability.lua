local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local world_mod = require(ReplicatedStorage.Shared.world)
local coords_mod = require(ReplicatedStorage.Shared.coords)
local team_mod = require(ReplicatedStorage.Shared.team)

type World = types.World
type Entity = types.Entity
type TeamId = types.TeamId
type EncodedCoordinate = types.EncodedCoordinate
type EntityId = types.EntityId
type HexCell = types.HexCell

-- Gets the valid candidates for a scout-like attack in a given range
function entity_attack_candidates(
	world: World,
	entity: Entity,
	range: number,
	player_team_id: TeamId
): { [EncodedCoordinate]: true }
	local candidates: { [EncodedCoordinate]: true } = {}
	for _, coord in world_mod.coords_filter(world, coords_mod.neighbors_leq(entity.primary_coordinate, range)) do
		if not world_mod.line_of_sight(world, entity.primary_coordinate, coord, player_team_id) then
			continue
		end

		candidates[coords_mod.encode_coord(coord)] = true
	end

	local taunts_on_cell: { [EntityId]: Entity } = util.table_filter_map(
		(world:get_cell(entity.primary_coordinate) :: HexCell).influences,
		function(_, taunt_id)
			local taunt = world.entities[taunt_id]
			if
				taunt.type == "taunt"
				and candidates[coords_mod.encode_coord(taunt.primary_coordinate)]
				and not team_mod.is_allied(world, taunt.owner, player_team_id)
				and taunt.owner ~= world.capturable_team
			then
				return taunt
			end
			return nil
		end
	)

	if next(taunts_on_cell) ~= nil then
		candidates = {}
		for _, taunt in taunts_on_cell do
			candidates[coords_mod.encode_coord(taunt.primary_coordinate)] = true
		end
	end
	return candidates
end

return {
	entity_attack_candidates = entity_attack_candidates,
}
