local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local registry_mod = require(script.Parent.registry)
local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults
local shared_entity_mod = require(ReplicatedStorage.Shared.entity)
local shared_behavior = shared_entity_mod.registry["stockpile"]

type Entity = types.Entity
type HexGrid = types.HexGrid

registry["stockpile"] = with_defaults {
	autogenerate_wires = true,
	on_completed = function(self: Entity, grid: HexGrid)
		if not self.inventory then
			self.inventory = {
				filter_item_type = "all",
				homogeneous = false,
				capacity = shared_behavior.inventory_capacity,
				items = {},
			}
		end
	end,
}

return {}
