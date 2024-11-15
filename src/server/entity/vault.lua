local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local registry_mod = require(script.Parent.registry)
local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults

type Entity = types.Entity
type HexGrid = types.HexGrid

registry.vault = with_defaults {
	autogenerate_wires = true,
	init = function(self: Entity, grid: HexGrid) end,
	on_completed = function(self: Entity, grid: HexGrid)
		local config = grid.entity_configurations[self.type]
		if not self.inventory then
			self.inventory = {
				filter = {
					type = "blacklist",
					items = {},
				},
				homogeneous = true,
				capacity = config.inventory_capacity,
				items = {},
			}
		end
	end,
}

return {}
