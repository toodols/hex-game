local researches_mod = require(script.Parent.researches)
local items_mod = require(script.Parent.items)
local cells = require(script.Parent.cells)
local types = require(script.Parent.types)

function format_text(grid: types.HexGrid, text: string)
	local namespaces = {
		research = researches_mod.researches,
		item = items_mod.item_names,
		cell = cells.cell_models,
		entity = grid.entity_configurations,
		quest = grid.quests,
		turn = grid.turn,
	}
	local result, _ = text:gsub("{[^}]+}", function(match)
		local inner = match:sub(2, -2):split "."
		local start = namespaces
		for _, prop in inner do
			start = start[prop]
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
		return tostring(start)
	end)
	return result
end

return {
	format_text = format_text,
}
