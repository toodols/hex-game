local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)

local util = require(ReplicatedStorage.Shared.util)
local visibility_mod = require(ReplicatedStorage.Shared.visibility)

local systems_mod = require(ServerScriptService.Server.systems)
local damage_mod = require(ServerScriptService.Server.damage)
local updates_mod = require(ServerScriptService.Server.updates)
local server_entity_mod = require(ServerScriptService.Server.entity)
local server_util = require(ServerScriptService.Server.util)

type HexGrid = types.HexGrid
type System = server_types.System
type ActionState = server_types.ActionState

function handle_ability_actions(grid: HexGrid, action_state: ActionState)
	for _, ability in
		util.table_extract(grid.action_queue, function(value)
			return (value.type == "ability")
		end)
	do
		local system = action_state.system_by_entity_id[ability.entity_id]
		local entity = grid.entities[ability.entity_id]
		if ability.ability_type == "scout_attack" or ability.ability_type == "turret_attack" then
			local config = grid.entity_configurations[entity.type]
			local cost = config.abilities[ability.ability_type].cost

			if not systems_mod.system_has_items(grid, action_state, system, cost) then
				continue
			end

			for item_type, amount in cost do
				systems_mod.system_consume_item_type(grid, action_state, system, item_type, amount)
			end

			table.insert(grid.action_queue, {
				type = "entity_event",
				event_type = "consumed_items",
				entity_id = ability.entity_id,
				items = cost,
			})

			local cell = grid:get_cell(ability.coordinate)
			assert(cell, "cell not found")

			updates_mod.add_update(grid, ability)
			for entity_id in
				damage_mod.damage_cells(grid, { cell.coordinate }, {
					type = "flat",
					amount = if ability.ability_type == "scout_attack" then 2 else 3,
					from = entity.id,
					lethal = true,
					friendly_fire = false,
				})
			do
				action_state.will_be_destroyed_entities[entity_id] = true
			end
		elseif ability.ability_type == "solution_use" then
			server_entity_mod.registry[entity.type].abilities[ability.ability_type](entity, grid)
			action_state.will_be_destroyed_entities[entity.id] = true
		elseif ability.ability_type == "disguise" then
			local coordinate = ability.coordinate
			-- get the entity to copy
			local cell = grid:get_cell(coordinate)
			if not cell then
				warn "invalid coordinate"
				continue
			end

			grid:query_entity {
				coordinate = coordinate,
				status = "complete",
			}
			-- get the list of entities, filter the ones visible to this team
			-- ignore entities that occupy more than one cell and sort it by layer
			local entities = util.table_filter(
				grid:query_entity {
					coordinate = coordinate,
					status = "complete",
				},
				function(target_entity)
					return visibility_mod.entity_visibility(grid, target_entity, entity.owner)
						and #target_entity.coordinates == 1
				end
			)
			table.sort(entities, function(a, b)
				return grid.entity_configurations[a.type].layer > grid.entity_configurations[b.type].layer
			end)

			local top = entities[1]
			if not top then
				continue
			end

			-- treat entity disguising as itself as resetting disguise
			if top == entity then
				if entity.disguise then
					grid.entities[entity.disguise].is_destroyed = true
					table.insert(grid.updates_buffer, {
						type = "entity_update",
						entity = grid.entities[entity.disguise],
					})
				end
				entity.disguise = nil
				table.insert(grid.updates_buffer, {
					type = "disguise",
					entity_id = entity.id,
				})
				continue
			end

			local copied = util.deep_copy(top)
			copied.disguise = nil
			copied.active = false
			copied.server_data.active = false
			copied.id = server_util.new_global_id()
			copied.primary_coordinate = entity.primary_coordinate
			copied.coordinates = entity.coordinates
			copied.owner = entity.owner
			grid.entities[copied.id] = copied
			entity.disguise = copied.id
			table.insert(grid.updates_buffer, {
				type = "entity_update",
				entity = copied,
			})
			table.insert(grid.updates_buffer, {
				type = "entity_disguise",
				entity_id = entity.id,
				disguise_id = copied.id,
			})
		end
	end
end

return {
	handle_ability_actions = handle_ability_actions,
}
