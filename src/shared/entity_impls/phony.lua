local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.phony = entity_mod.with_defaults {
	type = "phony",
	name = "Phony",
	description = "Can disguise as a different building in a range of {entity.phony.abilities.disguise.range}. On death, generate 1 {item.tek}",
	max_health = 1,
	build_time = 1,
	cost = {
		bar = 1,
		tar = 1,
	},
	abilities = {
		disguise = {
			range = 4,
		},
	},
	-- required_research = {
	-- 	"phony",
	-- },
	layer = entity_mod.LAYER.building,
}

return {}
