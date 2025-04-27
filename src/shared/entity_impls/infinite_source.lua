local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.infinite_source = entity_mod.with_defaults {
	type = "infinite_source",
	name = "Infinite Source",
	buildable = false,
	description = "Debug item that gives unlimited items",
	max_health = math.huge,
	layer = entity_mod.LAYER.building,
}

return {}
