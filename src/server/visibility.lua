local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local team_mod = require(ReplicatedStorage.Shared.team)
local coords = require(ReplicatedStorage.Shared.coords)
type TeamId = types.TeamId
type Entity = types.Entity
type HexCell = types.HexCell
type World = types.World
type CellTeamVisibility = types.CellTeamVisibility
type CubicCoordinate = types.CubicCoordinate
type EncodedCoordinate = types.EncodedCoordinate

-- Computes cell visibility for each team and returns a set of cells for each team that has changed to visible
function compute_visibility(world: World): { [TeamId]: { [EncodedCoordinate]: boolean } }
	local changed_to_visible: { [TeamId]: { [EncodedCoordinate]: boolean } } = {}
	local old_vis: { [EncodedCoordinate]: { [TeamId]: any } } = {}
	-- reset server_data.visibility for all cells
	for encoded_coord, cell in world.cells do
		old_vis[encoded_coord] = cell.server_data.visibility
		cell.server_data.visibility = {}
	end

	local function add_visibility(coord: CubicCoordinate, team_id: TeamId, type: string)
		local encoded_coord = coords.encode_coord(coord)
		local cell = world:get_cell(coord)
		if not cell then
			return
		end
		changed_to_visible[team_id] = changed_to_visible[team_id] or {}
		old_vis[encoded_coord] = old_vis[encoded_coord] or {}
		if not cell_visibility(old_vis[encoded_coord][team_id]) then
			changed_to_visible[team_id][encoded_coord] = true
		end
		cell.server_data.visibility[team_id] = cell.server_data.visibility[team_id] or {}
		cell.server_data.visibility[team_id][type] = true
	end

	-- loop through each entity and apply r=2
	-- some other entities will have extra illuminations
	for _, entity in world:active_entities() do
		if entity.status ~= "complete" or entity.is_destroyed then
			continue
		end

		-- occupying a portal gives r<=1 visibility for each connected portal
		local cell = world:get_cell(entity.primary_coordinate)
		if cell.type == "portal" and cell.portal.open then
			for _, connected in cell.portal.group do
				-- ignore self
				if coords.coords_eq(connected, entity.primary_coordinate) then
					continue
				end
				local neighbors = coords.neighbors_leq(connected, 1)
				for _, coord in neighbors do
					add_visibility(coord, entity.owner, "portal")
				end
			end
		end

		-- local cell = world:get_cell(entity.primary_coordinate)
		-- local server_behavior = server_entity_mod.registry[entity.type]
		local illuminated = coords.neighbors_leq(entity.primary_coordinate, 2)
		if entity.type == "scout" then
			illuminated = coords.neighbors_leq(entity.primary_coordinate, 3)
		end
		for _, neighbor_coord in illuminated do
			add_visibility(neighbor_coord, entity.owner, "illumination")
		end
	end

	for _, team in world.teams do
		if team.server_data.visibility == "fogless" or team.server_data.visibility == "perfect" then
			changed_to_visible[team.id] = changed_to_visible[team.id] or {}
			for _, cell in world.cells do
				local encoded_coord = coords.encode_coord(cell.coordinate)
				old_vis[encoded_coord] = old_vis[encoded_coord] or {}
				if not cell_visibility(old_vis[encoded_coord][team.id]) then
					changed_to_visible[team.id][encoded_coord] = true
				end
				cell.server_data.visibility[team.id] = cell.server_data.visibility[team.id] or {}
				cell.server_data.visibility[team.id].fogless = true
			end
		end
	end

	return changed_to_visible
end

function cell_visibility(visibility: CellTeamVisibility?)
	return visibility and (visibility.contact or visibility.fogless or visibility.portal or visibility.illumination)
end

function entity_visibility(world: World, entity: Entity, team: TeamId): boolean
	if entity.server_data.always_visible then
		return true
	end

	if entity.server_data.always_visible_for[team] then
		return true
	end

	-- this entity is visible if it is owned by this coalition
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
	compute_visibility = compute_visibility,
}
