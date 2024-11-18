local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local registry_mod = require(script.Parent.registry)
local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults

type Entity = types.Entity
type HexGrid = types.HexGrid

registry.impression = with_defaults {
	init = function(self: Entity, grid: HexGrid)
		self.decayable = false
	end,
	on_completed = function(self: Entity, grid: HexGrid) end,
}

return {}
