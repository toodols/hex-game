local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)
local team_mod = require(ReplicatedStorage.Shared.team)
local coords = require(ReplicatedStorage.Shared.coords)
local effect_mod = require(script.Parent.effect)
local server_entity_mod = require(ServerScriptService.Server.entity)

type TeamId = types.TeamId
type Entity = types.Entity
type HexCell = types.HexCell
type World = types.World
type CellTeamVisibility = types.CellTeamVisibility
type CubicCoordinate = types.CubicCoordinate
type EncodedCoordinate = types.EncodedCoordinate
type SerializeFor = server_types.SerializeFor

-- Computes cell visibility for each team
-- This also sets changed_to_true field of visibility
function compute_visibility(world: World)
	local old_vis: { [EncodedCoordinate]: { [TeamId]: boolean } } = {}
	-- reset server_data.visibility for all cells, except for changed_to_true
	for encoded_coord, cell in world.cells do
		old_vis[encoded_coord] = {}
		for team_id, visibility in cell.server_data.visibility do
			old_vis[encoded_coord][team_id] = cell_visibility(visibility)
			cell.server_data.visibility[team_id] = {
				["changed_to_true"] = visibility.changed_to_true,
			}
		end
	end

	local function add_visibility(coord: CubicCoordinate, team_id: TeamId, type: string)
		local encoded_coord = coords.encode_coord(coord)
		local cell = world:get_cell(coord)
		if cell == nil then
			return
		end

		cell.server_data.visibility[team_id] = cell.server_data.visibility[team_id] or {}
		if not old_vis[encoded_coord][team_id] then
			cell.server_data.visibility[team_id].changed_to_true = true
		end
		cell.server_data.visibility[team_id][type] = true
	end

	-- loop through each entity and apply r=2
	-- some other entities will have extra illuminations
	for _, entity in world:active_entities() do
		local server_behavior = server_entity_mod.registry[entity.type]
		if entity.status ~= "complete" or server_behavior.incorporeal then
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
		local neighbors = coords.neighbors_leq(entity.primary_coordinate, 2)
		for _, coord in neighbors do
			add_visibility(coord, entity.owner, "contact")
		end

		for _, neighbor_coord in server_behavior.illumination(entity, world) do
			add_visibility(neighbor_coord, entity.owner, "illumination")
		end
	end

	for _, team in world.teams do
		if team.server_data.visibility == "fogless" or team.server_data.visibility == "perfect" then
			for _, cell in world.cells do
				local encoded_coord = coords.encode_coord(cell.coordinate)
				cell.server_data.visibility[team.id] = cell.server_data.visibility[team.id] or {}
				if not old_vis[encoded_coord][team.id] then
					cell.server_data.visibility[team.id].changed_to_true = true
				end
				cell.server_data.visibility[team.id].fogless = true
			end
		end
	end
end

function cell_visibility(visibility: CellTeamVisibility?)
	return visibility and (visibility.contact or visibility.fogless or visibility.portal or visibility.illumination)
end

function entity_visibility(world: World, serialize_for: SerializeFor, entity: Entity): boolean
	if entity.server_data.always_visible then
		return true
	end

	if serialize_for.team == nil then
		return true
	end

	if entity.server_data.always_visible_for[serialize_for.team] then
		return true
	end

	if world.teams[serialize_for.team].server_data.visibility == "perfect" then
		return true
	end

	-- this entity is visible if it is owned by this coalition
	if team_mod.is_allied(world, entity.owner, serialize_for.team) then
		return true
	end

	if #effect_mod.get_effects(entity, "hidden") > 0 then
		return false
	end

	if entity.server_data.is_disguise_of ~= nil then
		local cell = world:get_cell(entity.primary_coordinate)
		if cell and cell_visibility(cell.server_data.visibility[serialize_for.team]) then
			return true
		end
		return false
	end

	local cell = world:get_cell(entity.primary_coordinate)
	if
		cell_visibility(cell.server_data.visibility[serialize_for.team])
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
