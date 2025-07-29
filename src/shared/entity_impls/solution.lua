local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.solution = entity_mod.with_defaults {
	type = "solution",
	name = "Solution",
	description = "When used: Heal all neighbor buildings for up to 2 health. Give 'Shield' effect to all neighbor entities.",
	short_description = "Consumable support building",
	entity_group = {
		["@consumable"] = true,
	},
	max_health = 0,
	build_time = 2,
	cost = {
		vit = 2,
	},
	abilities = {
		activate = {
			type = "solution_activate",
			shield_health = 1,
			shield_duration = 3,
			heal_amount = 2,
		} :: any,
	},
	construction_condition = {
		nearby = { "extractor" },
	},
	can_revive = true,
	layer = entity_mod.LAYER.building,
}

return {}
