local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.suggestion = entity_mod.with_defaults {
	type = "suggestion",
	name = "Suggestion",
	description = "Activate to convert enemies on this tile to this team.",
	max_health = 1,
	build_time = 1,
	cost = {
		pow = 2,
		vit = 2,
	},
	layer = entity_mod.LAYER.building,
}

return {}
