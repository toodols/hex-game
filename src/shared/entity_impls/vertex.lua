local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.vertex = entity_mod.with_defaults {
	type = "vertex",
	name = "Vertex",
	description = "Allows transfer of power and items between building",
	max_health = 0,
	build_time = 0, -- builds immediately in the next action phase
	cost = {
		bar = 1,
	},
	abilities = {},
	layer = entity_mod.LAYER.vertex,
}

return {}
