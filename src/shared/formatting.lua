local researches_mod = require(script.Parent.researches)
local items_mod = require(script.Parent.items)
local cells = require(script.Parent.cells)
local types = require(script.Parent.types)

function resolve_path(namespaces: any, path: string)
	local parts = path:split "."
	local start = namespaces
	for _, part in parts do
		start = start[part]
		if not start then
			return nil
		end
	end
	return start
end
function format_text_raw(text: string, namespaces: { [string]: any }, depth: number?)
	if depth and depth > 5 then
		warn "formatting exceeds max depth"
		return text
	end
	local result, _ = text:gsub("{[^}]+}", function(match)
		local inner = match:sub(2, -2)

		local question = inner:split "?"
		local start
		if #question == 1 then
			start = resolve_path(namespaces, question[1])
		elseif #question == 2 then
			local then_else_paths = question[2]:split ":"
			local if_val = resolve_path(namespaces, question[1])

			if if_val then
				start = resolve_path(namespaces, then_else_paths[1])
			elseif then_else_paths[2] then
				start = resolve_path(namespaces, then_else_paths[2])
			else
				start = ""
			end
		else
			error "too many"
		end

		if typeof(start) == "table" then
			if start.name then
				return start.name
			else
				local format_cost = ""
				for item, amount in start do
					format_cost ..= amount .. " " .. item .. "  "
				end
				return format_cost
			end
		end
		return format_text_raw(tostring(start), namespaces, if depth then depth + 1 else 1)
	end)
	return result
end
function format_text(grid: types.HexGrid, text: string, ns: { [string]: any }?, depth: number?)
	local namespaces = {
		research = researches_mod.researches,
		item = items_mod.item_names,
		cell = cells.cell_models,
		entity = grid.entity_configurations,
		quest = grid.quests,
		turn = grid.turn,
	}
	if ns then
		for key, value in ns do
			namespaces[key] = value
		end
	end
	return format_text_raw(text, namespaces, depth)
end

return {
	format_text = format_text,
	format_text_raw = format_text_raw,
}
