local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local registry_mod = require(script.Parent.registry)
local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults
local shared_entity_mod = require(ReplicatedStorage.Shared.entity)
local shared_behavior = shared_entity_mod.registry["vault"]

type Entity = types.Entity
type HexGrid = types.HexGrid

registry["vault"] = with_defaults {
	autogenerate_wires = true,
	init = function(self: Entity, grid: HexGrid) end,
	on_completed = function(self: Entity, grid: HexGrid)
		if not self.inventory then
			self.inventory = {
				filter_item_type = "all",
				homogeneous = true,
				capacity = shared_behavior.inventory_capacity,
				items = {},
			}
		end
	end,
}

return {}
