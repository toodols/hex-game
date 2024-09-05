local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local util = require(ReplicatedStorage.Shared.util)
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)
local items_mod = require(ReplicatedStorage.Shared.items)
type HexGrid = types.HexGrid
type System = server_types.System
type ActionState = server_types.ActionState
type Item = types.Item
type Entity = types.Entity

-- consume items from inventories, prioritizing overflow_items
function system_consume_item_type(grid: HexGrid, action_state: ActionState, system: System, request_item, difference)
	local infinite_source = util.table_any(util.table_keys(system.entities), function(entity_id)
		return grid.entities[entity_id].type == "infinite_source"
	end)
	if infinite_source then
		return difference
	end

	local net = 0
	local overflow_count = items_mod.count_items(system.overflow_items, request_item)

	-- first using leftovers, then nonempty inventories
	if overflow_count > 0 then
		local effective = math.min(difference, overflow_count)
		difference -= effective

		items_mod.consume_items(system.overflow_items, { [request_item] = effective })
		net += effective
	end

	if difference > 0 then
		local nonempty_inventory_entities: { Entity } = util.table_filter_map(
			util.table_keys(system.entities),
			function(entity_id)
				local inventory = grid.entities[entity_id].inventory
				if inventory and #inventory.items > 0 then
					return grid.entities[entity_id]
				end
			end
		)
		for _, inventory_entity in nonempty_inventory_entities do
			-- extract a max of difference of item from inventory_entity.inventory.items
			local extracted = util.table_extract(inventory_entity.inventory.items, function(item, count)
				return item == request_item and count < difference
			end)
			difference -= #extracted
			net += #extracted
			action_state.dirty_entities[inventory_entity.id] = action_state.dirty_entities[inventory_entity.id] or {}
			action_state.dirty_entities[inventory_entity.id].everyone = true
		end
	end
	return net
end

-- returns true if the inventories + overflow_items can satisfy the request_items
function system_has_items(
	grid: HexGrid,
	action_state: ActionState,
	system: System,
	request_items: { [Item]: number? }
): boolean
	local infinite_source = util.table_any(util.table_keys(system.entities), function(entity_id)
		return grid.entities[entity_id].type == "infinite_source"
	end)
	if infinite_source then
		return true
	end

	local accumulator = {}
	for _, item in system.overflow_items do
		accumulator[item] = (accumulator[item] or 0) + 1
	end
	if items_mod.accumulator_satisfies_target(accumulator, request_items) then
		return true
	end

	local nonempty_inventory_entities: { Entity } = util.table_filter_map(
		util.table_keys(system.entities),
		function(entity_id)
			local inventory = grid.entities[entity_id].inventory
			if inventory and #inventory.items > 0 then
				return grid.entities[entity_id]
			end
		end
	)
	repeat
		local inventory_entity = table.remove(nonempty_inventory_entities, #nonempty_inventory_entities)
		if not inventory_entity then
			return false
		end
		items_mod.inventory_sum(accumulator, inventory_entity.inventory.items)
	until items_mod.accumulator_satisfies_target(accumulator, request_items)

	return true
end

-- add items to inventories in the system, then add overflow to overflow_items
function system_add_items(grid: HexGrid, action_state: ActionState, system: System, items: { Item })
	local open_inventory_entities: { Entity } = util.table_filter_map(
		util.table_keys(system.entities),
		function(entity_id)
			local inventory = grid.entities[entity_id].inventory
			if inventory and inventory.capacity > #inventory.items then
				return grid.entities[entity_id]
			end
		end
	)
	-- attempt to put as many of these items in inventories first
	while #open_inventory_entities > 0 and #items > 0 do
		local target: Entity = open_inventory_entities[#open_inventory_entities]
		if items_mod.inventory_deposit(target.inventory, items) then
			action_state.dirty_entities[target.id] = action_state.dirty_entities[target.id] or {}
			action_state.dirty_entities[target.id].everyone = true
		else
			open_inventory_entities[#open_inventory_entities] = nil
		end
		if target.inventory.capacity == #target.inventory.items then
			open_inventory_entities[#open_inventory_entities] = nil
		end
	end
	for _, item in items do
		table.insert(system.overflow_items, item)
	end
end

return {
	system_consume_item_type = system_consume_item_type,
	system_has_items = system_has_items,
	system_add_items = system_add_items,
}
