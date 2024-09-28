-- Entities can publish events to nearby neighbors
-- Neighbors can choose to listen for events to react

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local server_entity_registry = require(script.Parent.entity.registry)
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(script.Parent.types)
local updates_mod = require(script.Parent.updates)

type HexGrid = types.HexGrid
type CubicCoordinate = types.CubicCoordinate
type EntityEvent = server_types.EntityEvent

function publish_event(grid: HexGrid, event: EntityEvent, coords: { CubicCoordinate })
	for _, coord in coords do
		local cell = grid:get_cell(coord)
		if not cell then
			continue
		end
		for entity_id in cell.entities do
			-- don't send event to self
			if entity_id == event.entity_id then
				continue
			end
			local entity = grid.entities[entity_id]
			local behavior = server_entity_registry.registry[entity.type]
			if behavior.on_event then
				behavior.on_event(entity, grid, event)
			end
		end
	end
	updates_mod.add_update(grid, {
		type = "entity_event",
		event = event,
	})
end

return {
	publish_event = publish_event,
}
