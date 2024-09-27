local ReplicatedStorage = game:GetService "ReplicatedStorage"
local registry_mod = require(script.Parent.registry)
local types = require(ReplicatedStorage.Shared.types)
type Entity = types.Entity
type HexGrid = types.HexGrid

registry_mod.registry["solution"] = registry_mod.with_defaults {
	init = function(self: Entity, grid: HexGrid)
		self.decayable = false
	end,
}

return {}
