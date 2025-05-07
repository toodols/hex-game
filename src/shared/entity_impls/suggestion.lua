local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.suggestion = entity_mod.with_defaults {
	type = "suggestion",
	name = "Suggestion",
	description = "When an enemy is built on this tile, destroy self and set the enemy building's owner to this team",
	max_health = 1,
	build_time = 1,
	cost = {
		tar = 2,
		vit = 1,
	},
	layer = entity_mod.LAYER.building,
}

return {}
