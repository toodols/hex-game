local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.necromancer = entity_mod.with_defaults {
	type = "necromancer",
	name = "Lich",
	short_description = "Can revive allied buildings",
	description = "On allied building death, spawn a grave at its location with 1 hp, then take 1 damage. In 3 turns, this grave will transform into the dead building with max hp set to 1.",
	range = 3,
	max_health = 4,
	build_time = 2,
	cost = {
		bar = 1,
		tar = 4,
	},
	abilities = {},
	layer = entity_mod.LAYER.building,
}

entity_mod.registry.grave = entity_mod.with_defaults {
	type = "grave",
	name = "Grave",
	buildable = false,
	description = "A grave left by a {entity.necromancer}",
	max_health = 1,
	build_time = 3,
	layer = entity_mod.LAYER.building,
}

return {}
