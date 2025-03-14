local ReplicatedStorage = game:GetService "ReplicatedStorage"
local cells = require(ReplicatedStorage.Shared.cells)
local researches_mod = require(script.Parent.researches)
local items_mod = require(script.Parent.items)
local types = require(script.Parent.types)
local methods = require(script.methods)

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
	return methods.format_text_raw(text, namespaces, depth)
end

return {
	format_text = format_text,
	format_text_raw = methods.format_text_raw,
	font = methods.font,
}
