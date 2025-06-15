local ReplicatedStorage = game:GetService "ReplicatedStorage"
local coords = require(ReplicatedStorage.Shared.coords)
local types = require(ReplicatedStorage.Shared.types)
local visibility_mod = require(script.Parent.visibility)
local team_mod = require(ReplicatedStorage.Shared.team)
local util = require(ReplicatedStorage.Shared.util)
local world_mod = require(ReplicatedStorage.Shared.world)

type World = types.World
type Entity = types.Entity
type TeamId = types.TeamId
type CubicCoordinate = types.CubicCoordinate

function presence_size(world: World, entity: Entity): number
	if entity.incorporeal then
		return -1
	end

	if entity.type == "obelisk" then
		return 0
	end

	if entity.owner == world.neutral_team and entity.type == "barrier" then
		return 0
	end

	if entity.owner ~= world.capturable_team and entity.status ~= "blueprint" and not entity.is_destroyed then
		return 1
	end

	return -1
end

function team_may_naively_place_blueprint(world: World, team: TeamId, coord: CubicCoordinate)
	local cell = world:get_cell(coord)

	-- if it does not have enemy presence
	if
		not util.table_any(util.table_keys(cell.server_data.presence), function(other_team)
			if not team_mod.is_allied(world, team, other_team) then
				return true
			end
			return false
		end)
	then
		return true
	end

	-- or is not owned by this coalition
	if team_mod.is_allied(world, cell.owner, team) then
		return true
	end

	-- or this team cannot see the building causing the enemy presence
	local can_see_enemy_presence = false
	for _, neighbor_cell in world_mod.into_cells(world, coords.neighbors_leq(coord, 1)) do
		local cell_is_visible = visibility_mod.cell_visibility(neighbor_cell.server_data.visibility[team])

		-- TODO: this does not support multi coordinate entities
		for entity_id in neighbor_cell.entities do
			local neighbor_entity = world.entities[entity_id]
			if
				(neighbor_entity.always_visible or cell_is_visible)
				and not team_mod.is_allied(world, neighbor_entity.owner, team)
				and presence_size(world, neighbor_entity)
					>= coords.coords_dist(coord, neighbor_entity.primary_coordinate)
			then
				can_see_enemy_presence = true
				break
			end
		end
	end

	if not can_see_enemy_presence then
		return true
	end



	return false
end

-- a presence prevents enemy teams from building on that cell
-- this also assigns ownership
function compute_presence(world: World)
	-- reset all presences
	for _, cell in world.cells do
		cell.server_data.presence = {}
	end
	for _, cell in world.cells do
		local owner
		for entity_id in cell.entities do
			local size = presence_size(world, world.entities[entity_id])
			if size >= 0 then
				owner = world.entities[entity_id].owner
				for _, coord in coords.neighbors_leq(cell.coordinate, size) do
					local neighbor = world:get_cell(coord)
					if neighbor == nil then
						continue
					end
					neighbor.server_data.presence[owner] = true
				end
			end
		end
		cell.owner = owner
	end
end

return {
	compute_presence = compute_presence,
	can_impose_presence = presence_size,
	team_may_naively_place_blueprint = team_may_naively_place_blueprint,
}
