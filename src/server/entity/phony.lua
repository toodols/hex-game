local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local registry_mod = require(script.Parent.registry)
local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults

type Entity = types.Entity
type HexGrid = types.HexGrid

registry["phony"] = with_defaults {
	autogenerate_wires = true,
	on_completed = function(self: Entity, grid: HexGrid) end,
}

return {}
