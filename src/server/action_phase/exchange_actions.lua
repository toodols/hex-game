local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)
local util = require(ReplicatedStorage.Shared.util)
local systems_mod = require(ServerScriptService.Server.systems)
local items_mod = require(ReplicatedStorage.Shared.items)
local updates_mod = require(ServerScriptService.Server.updates)

type World = types.World
type EntityAction = types.EntityAction

function handle_exchange_actions(world: World)
	for _, exchange_action: any in
		util.table_extract(world.action_queue, function(action)
			return (action.type == "exchange" or action.type == "exchange_promise")
		end)
	do
		local system = world.systems[world.entity_system_map[exchange_action.entity_id]]
		if system == nil then
			print(world)
			print(exchange_action.entity_id)
		end
		local input_items = exchange_action.input_items
		local output_items = util.deep_copy(exchange_action.output_items)
		local input_power = exchange_action.input_power or 0
		local output_power = exchange_action.output_power or 0
		if
			(input_items and not systems_mod.system_has_items(world, system, input_items))
			or (system.power < input_power)
		then
			table.insert(world.action_queue, exchange_action)
			continue
		end
		if input_items then
			for item_type, amount in input_items do
				systems_mod.system_consume_item_type(world, system, item_type, amount)
			end
			local event = {
				type = "entity_event",
				event_type = "consumed_items",
				entity_id = exchange_action.entity_id,
				items = input_items,
			}
			table.insert(world.action_queue, event)
			world:add_update(event)
		end
		system.power -= input_power
		if exchange_action.on_success then
			exchange_action.on_success(world, system)
		end
		if output_items then
			-- system_add_items mutates output_items so count it beforehand
			local counted_output_items = items_mod.into_counted_items(output_items)
			systems_mod.system_add_items(world, system, output_items)
			local event = {
				type = "entity_event",
				event_type = "produced_items",
				entity_id = exchange_action.entity_id,
				items = counted_output_items,
			}
			table.insert(world.action_queue, event)
			world:add_update(event)
		end
		system.power += output_power
	end
end

return { handle_exchange_actions = handle_exchange_actions }
