local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.obelisk = entity_mod.with_defaults {
	type = "obelisk",
	name = "Obelisk",
	description = "Worthless trophy",
	max_health = 20,
	build_time = 1,
	cost = {
		bar = 20,
	},
	layer = entity_mod.LAYER.building,
}

return {}
