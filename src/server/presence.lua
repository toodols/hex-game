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

function can_impose_presence(world: World, entity: Entity)
	if entity.incorporeal then
		return false
	end
	if entity.owner ~= world.neutral_team and entity.status ~= "blueprint" and not entity.is_destroyed then
		return true
	end

	-- neutral barrier imposes a presence
	if entity.owner == world.neutral_team and entity.type == "barrier" then
		return true
	end

	return false
end

function team_may_naively_place_blueprint(world: World, team: TeamId, coord: CubicCoordinate)
	local cell = world:get_cell(coord)

	-- if this cell is not visible
	if not visibility_mod.cell_visibility(cell.server_data.visibility[team]) then
		return true
	end

	-- or does not have enemy presence
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

		for entity_id in neighbor_cell.entities do
			local neighbor_entity = world.entities[entity_id]
			if
				(neighbor_entity.always_visible or cell_is_visible)
				and not team_mod.is_allied(world, neighbor_entity.owner, team)
				and can_impose_presence(world, neighbor_entity)
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
	local neutral_team = world.neutral_team
	for _, cell in world.cells do
		local owner
		for entity_id in cell.entities do
			if can_impose_presence(world, world.entities[entity_id]) then
				owner = world.entities[entity_id].owner
				break
			end
		end
		cell.owner = owner
	end
	for _, cell in world.cells do
		local presence = {}
		for _, coord in coords.neighbors_leq(cell.coordinate, 1) do
			local neighbor = world:get_cell(coord)
			-- teams impose a presence in r<=1
			-- neutral teams impose a presence in r=0
			if
				neighbor
				and neighbor.owner
				and (neighbor.owner ~= neutral_team or coords.coords_eq(cell.coordinate, coord))
			then
				presence[neighbor.owner] = true
			end
		end
		-- if not util.deep_equal(presence, cell.server_data.presence) then
		-- if mark_dirty then
		-- 	cell.server_data.dirty = true
		-- end
		-- end

		cell.server_data.presence = presence
	end
end

return {
	compute_presence = compute_presence,
	can_impose_presence = can_impose_presence,
	team_may_naively_place_blueprint = team_may_naively_place_blueprint,
}
