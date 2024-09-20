-- Entities can publish events to nearby neighbors
-- Neighbors can choose to listen for events to react

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local server_entity_registry = require(script.Parent.entity.registry)
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(script.Parent.types)
type HexGrid = types.HexGrid
type CubicCoordinate = types.CubicCoordinate
type EntityEvent = server_types.EntityEvent

function publish_event(grid: HexGrid, event: EntityEvent, coords: { CubicCoordinate })
	for _, coord in coords do
		local cell = grid:get_cell(coord)
		if not cell then
			continue
		end
		for _, entity_id in cell.entities do
			local entity = grid.entities[entity_id]
			local behavior = server_entity_registry.registry[entity.type]
			if behavior.on_event then
				behavior.on_event(entity, grid, event)
			end
		end
	end
	table.insert(grid.updates_buffer[#grid.updates_buffer], {
		type = "entity_event",
		event = event,
	})
end

return {
	publish_event = publish_event,
}
