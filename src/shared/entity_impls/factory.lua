local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.factory = entity_mod.with_defaults {
	type = "factory",
	name = "Alchemist",
	description = "Creates items out of materials",
	max_health = 3,
	build_time = 1,
	cost = {
		rad = 2,
		bar = 2,
	},
	can_revive = true,
	can_disable = true,
	construction_condition = {
		nearby = { "stockpile", "vault" },
	},
	recipes = {
		bar_to_vit = {
			layout_order = 1,
			input_items = {
				bar = 2,
			},
			output_items = {
				"vit",
			},
		},
		bar_to_rad = {
			layout_order = 2,
			input_items = {
				bar = 2,
			},
			output_items = {
				"rad",
			},
		},
		tar = {
			layout_order = 3,
			input_items = {
				tar = 3,
			},
			output_items = {
				"pow",
				"bar",
				"bar",
			},
		},
	},
	layer = entity_mod.LAYER.building,
}

return {}
