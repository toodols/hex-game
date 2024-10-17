local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)
local publish_event = require(ServerScriptService.Server.event).publish_event
local util = require(ReplicatedStorage.Shared.util)
local systems_mod = require(ServerScriptService.Server.systems)
local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)
local items_mod = require(ReplicatedStorage.Shared.items)

type HexGrid = types.HexGrid
type System = server_types.System
type ActionState = server_types.ActionState
type EntityAction = server_types.EntityAction

function handle_exchange_actions(grid: HexGrid, action_state: ActionState)
	for _, exchange_action: any in
		util.table_extract(action_state.queue, function(action)
			return (action.type == "exchange" or action.type == "exchange_promise")
		end)
	do
		local system = action_state.system_by_entity_id[exchange_action.entity_id]
		local entity = grid.entities[exchange_action.entity_id]
		local input_items = exchange_action.input_items
		local output_items = exchange_action.output_items
		local input_power = exchange_action.input_power or 0
		local output_power = exchange_action.output_power or 0
		if
			(input_items and not systems_mod.system_has_items(grid, action_state, system, input_items))
			or (system.power < input_power)
		then
			table.insert(action_state.queue, exchange_action)
			continue
		end
		if input_items then
			for item_type, amount in input_items do
				systems_mod.system_consume_item_type(grid, action_state, system, item_type, amount)
			end
			publish_event(grid, {
				type = "consumed_items",
				entity_id = exchange_action.entity_id,
				items = input_items,
			}, hex_grid_mod.neighbors_leq(entity.primary_coordinate, 1))
		end
		system.power -= input_power
		if exchange_action.on_success then
			exchange_action.on_success(grid, action_state, system)
		end
		if output_items then
			-- system_add_items mutates output_items so count it beforehand
			local counted_output_items = items_mod.into_counted_items(output_items)
			systems_mod.system_add_items(grid, action_state, system, output_items)
			publish_event(grid, {
				type = "produced_items",
				entity_id = exchange_action.entity_id,
				items = counted_output_items,
			}, hex_grid_mod.neighbors_leq(entity.primary_coordinate, 1))
		end
		system.power += output_power
	end
end

return { handle_exchange_actions = handle_exchange_actions }
