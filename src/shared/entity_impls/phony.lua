local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.phony = entity_mod.with_defaults {
	type = "phony",
	name = "Phony",
	description = "Can disguise as a different building in a range of 4.",
	max_health = 3,
	build_time = 1,
	cost = {
		bar = 4,
	},
	abilities = {
		disguise = {
			range = 4,
		},
	},
	-- required_research = {
	-- 	"phony",
	-- },
	can_capture = true,
	layer = entity_mod.LAYER.building,
}

return {}
