local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local registry_mod = require(script.Parent.registry)
local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults

type Entity = types.Entity
type HexGrid = types.HexGrid

registry.phony = with_defaults {
	autogenerates_vertex = true,
	update = function(self: Entity) end,
	on_completed = function(self: Entity, grid: HexGrid) end,
}

return {}
