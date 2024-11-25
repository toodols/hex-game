local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)

local util = require(ReplicatedStorage.Shared.util)
local systems_mod = require(ServerScriptService.Server.systems)
local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)
local damage_mod = require(ServerScriptService.Server.damage)
local updates_mod = require(ServerScriptService.Server.updates)
local server_entity_mod = require(ServerScriptService.Server.entity)

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
		end
	end
end

return {
	handle_ability_actions = handle_ability_actions,
}
