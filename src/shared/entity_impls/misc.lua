local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.big = entity_mod.with_defaults {
	type = "big",
	name = "Big",
	max_health = 3,
	build_time = 0,
	offsets = {
		{ 0, 0, 0 },
		{ 0, 1, -1 },
		{ 1, 0, -1 },
	},
	buildable = false,
	layer = entity_mod.LAYER.building,
}

return {}
