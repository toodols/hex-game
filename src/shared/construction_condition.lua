local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local world_mod = require(ReplicatedStorage.Shared.world)
local coords_mod = require(ReplicatedStorage.Shared.coords)
local util = require(ReplicatedStorage.Shared.util)

type CubicCoordinate = types.CubicCoordinate
type World = types.World
type ConstructionCondition = types.ConstructionCondition
type TeamId = types.TeamId

type ConstructionConditionStatus = {
	built_on: { { entity_type: string, ok: boolean } }?,
	nearby: { { entity_type: string, ok: boolean } }?,
	not_nearby: { { entity_type: string, ok: boolean } }?,
}

function validate_condition(
	world: World,
	coordinates: { CubicCoordinate },
	team: TeamId,
	condition: ConstructionCondition,
	permit_blueprints: boolean?
): (boolean, ConstructionConditionStatus)
	local status = {}
	local built_on_ok = true
	local nearby_ok = true
	local not_nearby_ok = true

	if condition.built_on then
		built_on_ok = false
		status.built_on = {}

		local entities_at_cell = {}
		for _, coordinate in coordinates do
			local cell = world:get_cell(coordinate)
			for entity_id in cell.entities do
				local entity = world.entities[entity_id]
				local config = world.entity_configurations[entity.type]
				entities_at_cell[entity.type] = true
				for group in config.entity_group do
					entities_at_cell[group] = true
				end
			end
		end

		for _, entity_type in condition.built_on do
			local ok = entities_at_cell[entity_type] ~= nil
			if ok then
				built_on_ok = true
			end
			table.insert(status.built_on, {
				entity_type = entity_type,
				ok = ok,
			})
		end
	end

	if condition.nearby or condition.not_nearby then
		local nearby_entity_types = {}
		for _, coord in world_mod.coords_filter(world, coords_mod.neighbors_many_leq(coordinates, 2)) do
			local cell = world:get_cell(coord)
			for entity_id in cell.entities do
				local entity = world.entities[entity_id]
				local config = world.entity_configurations[entity.type]
				if entity.owner == team and (entity.status == "complete" or permit_blueprints) then
					nearby_entity_types[entity.type] = true
					for group in config.entity_group do
						nearby_entity_types[group] = true
					end
				end
			end
		end
		if condition.nearby then
			nearby_ok = false
			status.nearby = {}
			for _, entity_type in condition.nearby do
				local ok = false
				if nearby_entity_types[entity_type] then
					nearby_ok = true
					ok = true
				end
				table.insert(status.nearby, {
					entity_type = entity_type,
					ok = ok,
				})
			end
		end

		if condition.not_nearby then
			not_nearby_ok = true
			status.not_nearby = {}
			for _, entity_type in condition.not_nearby do
				local ok = true
				if nearby_entity_types[entity_type] then
					not_nearby_ok = false
					ok = false
				end
				table.insert(status.not_nearby, {
					entity_type = entity_type,
					ok = ok,
				})
			end
		end
	end
	return built_on_ok and nearby_ok and not_nearby_ok, status
end

function cell_blocked(world: World, coord: CubicCoordinate, team: TeamId, entity_type: string)
	local cell = world:get_cell(coord)
	local entity_config = world.entity_configurations[entity_type]
	if not cell then
		return true
	end
	return util.table_any(
		util.table_map(cell.entities, function(_, id)
			return world.entities[id]
		end),
		function(entity)
			if entity.owner == team then
				return world.entity_configurations[entity.type].layer == entity_config.layer
			end
			return nil
		end
	)
end

return {
	cell_blocked = cell_blocked,
	validate_condition = validate_condition,
}
