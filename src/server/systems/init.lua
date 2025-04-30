local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local util = require(ReplicatedStorage.Shared.util)
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)
local items_mod = require(ReplicatedStorage.Shared.items)
local updates_mod = require(ServerScriptService.Server.updates)
local compute_systems = require(script.compute_systems).compute_systems

type World = types.World
type SystemExtended = server_types.SystemExtended
type ActionState = server_types.ActionState
type Item = types.Item
type Entity = types.Entity
type Inventory = types.Inventory

-- consume items from inventories, prioritizing overflow_items
function system_consume_item_type(
	world: World,
	action_state: ActionState,
	system: SystemExtended,
	request_item: Item,
	amount: number
)
	local infinite_source = util.table_any(util.table_keys(system.entities), function(entity_id)
		return world.entities[entity_id].type == "infinite_source"
	end)
	if infinite_source then
		return amount
	end

	local net = 0
	local overflow_count = items_mod.count_items(system.overflow_items, request_item)

	-- first using leftovers, then nonempty inventories
	if overflow_count > 0 then
		local effective = math.min(amount, overflow_count)
		amount -= effective

		items_mod.consume_items(system.overflow_items, { [request_item] = effective })
		net += effective
	end

	if amount > 0 then
		local nonempty_inventory_entities: { Entity } = util.table_filter_map(
			util.table_keys(system.entities),
			function(entity_id)
				local inventory = world.entities[entity_id].inventory
				if inventory and #inventory.items > 0 then
					return world.entities[entity_id]
				end
				return nil
			end
		)
		for _, inventory_entity in nonempty_inventory_entities do
			-- extract a max of difference of item from inventory_entity.inventory.items
			local extracted = util.table_extract(inventory_entity.inventory.items, function(item, count)
				return item == request_item and count < amount
			end)
			amount -= #extracted
			net += #extracted
			updates_mod.add_update(world, {
				type = "entity_update",
				entity = inventory_entity,
			})
		end
	end
	return net
end

-- returns true if the inventories + overflow_items can satisfy the request_items
function system_has_items(
	world: World,
	action_state: ActionState,
	system: SystemExtended,
	request_items: { [Item]: number? }
): boolean
	local infinite_source = util.table_any(util.table_keys(system.entities), function(entity_id)
		return world.entities[entity_id].type == "infinite_source"
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
			local inventory = world.entities[entity_id].inventory
			if inventory and #inventory.items > 0 then
				return world.entities[entity_id]
			end
			return nil
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
function system_add_items(world: World, action_state: ActionState, system: SystemExtended, items: { Item })
	local open_inventory_entities: { Entity & { inventory: Inventory } } = util.table_filter_map(
		util.table_keys(system.entities),
		function(entity_id)
			local inventory = world.entities[entity_id].inventory
			if inventory and inventory.capacity > #inventory.items then
				return world.entities[entity_id]
			end
			return nil
		end
	)
	-- attempt to put as many of these items in inventories first
	while #open_inventory_entities > 0 and #items > 0 do
		local target = open_inventory_entities[#open_inventory_entities]
		if items_mod.inventory_deposit(target.inventory, items) then
			updates_mod.add_update(world, {
				type = "entity_update",
				entity = target,
			})
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
	compute_systems = compute_systems,
}
