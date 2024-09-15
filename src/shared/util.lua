function set_transparency(instance_tree: Instance, transparency: number)
	if instance_tree:IsA "BasePart" then
		(instance_tree :: BasePart).Transparency = transparency
	end
	for _, basepartq in (instance_tree:GetDescendants()) do
		if basepartq:IsA "BasePart" then
			(basepartq :: BasePart).Transparency = transparency
		end
	end
end

function table_map<K, In, Out>(tab: { [K]: In }, fn: (v: In) -> Out): { [K]: Out }
	local new_table = {}
	for k, v in tab do
		new_table[k] = fn(v)
	end
	return new_table
end

-- removes any number of needles from table in place
function table_remove_needle<T>(tab: { T }, needle: T)
	local idx
	while true do
		idx = table.find(tab, needle)
		if not idx then
			break
		end
		table.remove(tab, idx)
	end
end

-- removes all values in `tab` that satisfy `pred` and returns the removed values
-- count is the number of extracted values
function table_extract<T>(tab: { T }, pred: (value: T, count: number) -> boolean): { T }
	local result = {}
	local j = 0
	for i = 1, #tab do
		local item = tab[i]
		if pred(item, #result) then
			table.insert(result, item)
			tab[i] = nil
		else
			tab[i] = nil
			j += 1
			tab[j] = item
		end
	end
	return result
end

-- flattens a 2d array into 1d
function table_flat<T>(tab: { { T } }): { T }
	local result: { T } = {}

	for _, inner_table in tab do
		for _, value in inner_table do
			table.insert(result, value)
		end
	end

	return result
end

-- returns the first value, if any, that satisfies `pred`
function table_find_pred<T>(tab: { T }, pred: (value: T) -> boolean): T?
	for _, value in tab do
		if pred(value) then
			return value
		end
	end
	return nil
end

-- creates a dictionary from a table of (K,V) entries
function table_from_entries<K, V>(tab: { { K | V } }): { [K]: V }
	local result = {}
	for _, entry in tab do
		result[entry[1]] = entry[2]
	end
	return result
end

-- filters out T which fails cond
function table_filter<K, T>(tab: { [K]: T }, cond: (T) -> boolean): { [K]: T }
	local result: any = {}
	for idx, value in tab do
		if cond(value) then
			if type(idx) == "number" then
				table.insert(result, value)
			else
				result[idx] = value
			end
		end
	end
	return result
end

-- maps I to O, excluding nil
function table_filter_map<K, I, O>(tab: { [K]: I }, fn: (I) -> O?): { [K]: O }
	local result: any = {}
	for idx, value in tab do
		local v = fn(value)
		if v then
			if type(idx) == "number" then
				table.insert(result, v)
			else
				result[idx] = v
			end
		end
	end
	return result
end

-- filters out nil values
function table_filter_nil<T>(tab: { T? }): { T }
	return table_filter(tab :: { T }, function(value)
		return value ~= nil
	end)
end

function table_fold<T, O>(tab: { T }, init: O, fun: (acc: O, cur: T) -> O): O
	for _, val in tab do
		init = fun(init, val)
	end
	return init
end

function table_any<T>(tab: { T }, pred: (value: T) -> boolean): boolean
	for _, v in tab do
		if pred(v) then
			return true
		end
	end
	return false
end

function table_every<T>(tab: { T }, pred: (value: T) -> boolean): boolean
	for _, v in tab do
		if not pred(v) then
			return false
		end
	end
	return true
end

function table_keys<K, V>(tab: { [K]: V }): { K }
	local keys = {}
	for k in tab do
		table.insert(keys, k)
	end
	return keys
end

-- merges two tables: join(a,b) = {...a, ...b}
function table_join<K, V>(a: { [K]: V }, b: { [K]: V }): { [K]: V }
	local result = {}
	for k, v in a do
		result[if type(k) == "number" then #a + k else k] = v
	end
	for k, v in b do
		result[if type(k) == "number" then #a + k else k] = v
	end
	return result
end

function deep_equal(a, b)
	if a == b then
		return true
	end

	if type(a) ~= "table" or type(b) ~= "table" then
		return false
	end

	for key in a do
		if not deep_equal(a[key], b[key]) then
			return false
		end
	end

	for key in b do
		if not deep_equal(a[key], b[key]) then
			return false
		end
	end

	return true
end

function deep_copy<T>(obj: T): T
	if type(obj) == "table" then
		local copy: any = {}
		for k, v in obj do
			copy[k] = deep_copy(v)
		end
		return copy
	else
		return obj
	end
end

function range(n: number)
	local t = {}
	for i = 1, n do
		table.insert(t, i)
	end
	return t
end

return {
	table_from_entries = table_from_entries,
	table_filter = table_filter,
	table_filter_nil = table_filter_nil,
	table_filter_map = table_filter_map,
	set_transparency = set_transparency,
	table_map = table_map,
	table_every = table_every,
	table_join = table_join,
	table_flat = table_flat,
	table_remove_needle = table_remove_needle,
	table_find_pred = table_find_pred,
	table_extract = table_extract,
	deep_equal = deep_equal,
	deep_copy = deep_copy,
	table_fold = table_fold,
	table_any = table_any,
	table_keys = table_keys,
	range = range,
}
