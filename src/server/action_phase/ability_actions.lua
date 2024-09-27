local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)
local publish_event = require(ServerScriptService.Server.event).publish_event
local server_util = require(ServerScriptService.Server.util)

local util = require(ReplicatedStorage.Shared.util)
local systems_mod = require(ServerScriptService.Server.systems)
local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)
local damage_mod = require(ServerScriptService.Server.damage)

type HexGrid = types.HexGrid
type System = server_types.System
type ActionState = server_types.ActionState

function handle_ability_actions(grid: HexGrid, action_state: ActionState, system: System)
	for _, ability in
		util.table_extract(action_state.queue, function(value)
			return (value.type == "ability") and table.find(util.table_keys(system.entities), value.entity_id) ~= nil
		end)
	do
		if ability.ability_type == "scout_attack" or ability.ability_type == "turret_attack" then
			local entity = grid.entities[ability.entity_id]
			local config = grid.entity_configurations[entity.type]
			local cost = config.abilities[ability.ability_type].cost

			server_util.mark_dirty_for_everyone(action_state, ability.entity_id)
			if not systems_mod.system_has_items(grid, action_state, system, cost) then
				continue
			end

			for item_type, amount in cost do
				systems_mod.system_consume_item_type(grid, action_state, system, item_type, amount)
			end

			publish_event(grid, {
				type = "consumed_items",
				entity_id = ability.entity_id,
				items = cost,
			}, hex_grid_mod.neighbors_leq(entity.primary_coordinate, 1))

			local cell = grid:get_cell(ability.coordinate)
			assert(cell, "cell not found")

			table.insert(grid.updates_buffer[#grid.updates_buffer], ability)
			damage_mod.apply_damage_on_cells(grid, { cell.coordinate }, {
				type = "flat",
				amount = if ability.ability_type == "scout_attack" then 1 else 3,
				from = entity.id,
				lethal = true,
				friendly_fire = false,
			}, action_state)
		elseif ability.ability_type == "solution_use" then
			print "solution use"
			local solution_entity = grid.entities[ability.entity_id]
			local solution_config = grid.entity_configurations[solution_entity.type]

			for _, cell in
				util.table_filter_map(hex_grid_mod.neighbors_leq(solution_entity.primary_coordinate, 1), function(coord)
					return grid:get_cell(coord)
				end)
			do
				for entity_id in cell.entities do
					local entity = grid.entities[entity_id]
					-- TODO: convert this to use damage_mod
					entity.health =
						math.max(entity.max_health, entity.health + solution_config.abilities.solution_use.heal_amount)
					entity.effects.shield = {
						type = "shield",
						health = solution_config.abilities.solution_use.shield_health,
						duration = solution_config.abilities.solution_use.shield_duration,
					}

					server_util.mark_dirty_for_everyone(action_state, entity_id)
				end
			end

			action_state.dead_entities[solution_entity.id] = true
		end
	end
end

return {
	handle_ability_actions = handle_ability_actions,
}
