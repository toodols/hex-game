local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.laboratory = entity_mod.with_defaults {
	type = "laboratory",
	name = "Sage",
	description = "Allows the research of advanced technology. Has a range of {entity.laboratory.range} tiles",
	range = 4,
	max_health = 3,
	build_time = 1,
	cost = {
		bar = 1,
		rad = 3,
	},
	can_revive = true,
	buildable = false,
	layer = entity_mod.LAYER.building,
}

return {}
