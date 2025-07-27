local ReplicatedStorage = game:GetService "ReplicatedStorage"

local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)

type Inventory = types.Inventory
type Item = types.Item
type Filter = types.Filter
type World = types.World
type HexCell = types.HexCell
type DepositType = types.DepositType

function count_items(tab: { Item }, needle: Item): number
	local count = 0
	for _, item in tab do
		if item == needle then
			count += 1
		end
	end
	return count
end
function consume_items(tab: { Item }, order: { [Item]: number })
	for item, amount in order do
		for i = 1, amount do
			table.remove(tab, table.find(tab, item))
		end
	end
end
function into_counted_items(items: { Item }): { [Item]: number }
	local counted = {}
	for _, item in items do
		counted[item] = (counted[item] or 0) + 1
	end
	return counted
end

-- Returns whether `item` is valid for `filter`
function item_match_filter(item: Item, filter: Filter): boolean
	if filter.type == "blacklist" then
		return not filter.items[item]
	else
		return filter.items[item]
	end
end

function item_can_deposit(item: Item, inventory: Inventory): boolean
	if not item_match_filter(item, inventory.filter) then
		return false
	end
	if inventory.homogeneous then
		if #inventory.items == 0 then
			return true
		else
			return inventory.items[1] == item
		end
	else
		return true
	end
end

-- Puts as many `mut items` as possible into `mut inventory`
-- Returns true if any items were extracted
function inventory_deposit(inventory: Inventory, items: { Item }): boolean
	if #items == 0 then
		return false
	end
	if inventory.homogeneous then
		local item_type
		if #inventory.items == 0 then
			item_type = util.table_find_pred(items, function(item)
				return item_match_filter(item, inventory.filter)
			end)
		else
			item_type = inventory.items[1]
		end

		local spare_capacity = inventory.capacity - #inventory.items
		local extracted = util.table_extract(items, function(item, count)
			return item == item_type and count < spare_capacity
		end)

		table.move(extracted, 1, #extracted, #inventory.items + 1, inventory.items)

		return #extracted > 0
	else
		local spare_capacity = inventory.capacity - #inventory.items
		local extracted = util.table_extract(items, function(item, count)
			return item_match_filter(item, inventory.filter) and count < spare_capacity
		end)
		table.move(extracted, 1, #extracted, #inventory.items + 1, inventory.items)
		return #extracted > 0
	end
end

-- Adds the items of `inventory` to `mut accumulator`
function inventory_sum(accumulator: { [Item]: number }, items: { Item })
	for _, item in items do
		if not accumulator[item] then
			accumulator[item] = 0
		end
		accumulator[item] += 1
	end
end

-- Returns whether `accumulator` has enough items to satisfy `target`
function accumulator_satisfies_target(accumulator: { [Item]: number? }, target: { [Item]: number? })
	for item, count in target do
		if count > 0 and (not accumulator[item] or accumulator[item] < count) then
			return false
		end
	end
	return true
end

local item_colors = {
	tar = Color3.new(0, 0, 0),
	bar = Color3.new(0.188235, 0.266667, 0.360784),
	dye = Color3.new(1, 1, 1),
	pow = Color3.new(1, 0, 0),
	zap = Color3.new(0.913725, 0.901960, 0.301960),
	rad = Color3.new(0.584313, 0.760784, 0.172549),
	vit = Color3.new(0.278431, 0.807843, 0.321568),
	tek = Color3.new(0.215686, 0.835294, 0.992156),
	dew = Color3.new(0.149019, 0.329411, 0.501960),
	goo = Color3.new(0.164705, 0.007843, 0.458823),
}

local item_names = {
	tar = "Tar",
	dye = "Dye",
	rad = "Rad",
	vit = "Vit",
	bar = "Bar",
	dew = "Dew",
	pow = "Pow",
	tek = "Tek",
	goo = "Goo",
	zap = "Zap",
}

return {
	count_items = count_items,
	consume_items = consume_items,
	into_counted_items = into_counted_items,
	item_match_filter = item_match_filter,
	item_can_deposit = item_can_deposit,
	inventory_deposit = inventory_deposit,
	inventory_sum = inventory_sum,
	accumulator_satisfies_target = accumulator_satisfies_target,
	item_colors = item_colors,
	item_names = item_names,
}
