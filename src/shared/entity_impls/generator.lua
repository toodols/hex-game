local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.generator = entity_mod.with_defaults {
	type = "generator",
	name = "Catalyst",
	description = "Generates {entity.generator.output_power} power per turn",
	max_health = 3,
	build_time = 1,
	output_power = 5,
	cost = {
		bar = 3,
		rad = 1,
	},
	abilities = {},
	layer = entity_mod.LAYER.building,
}

return {}
