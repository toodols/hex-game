local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.factory = entity_mod.with_defaults {
	type = "factory",
	name = "Alchemist",
	description = "Creates items out of materials",
	max_health = 3,
	build_time = 1,
	cost = {
		bar = 4,
	},
	can_disable = true,
	recipes = {
		vit_to_tek = {
			layout_order = 1,
			input_items = {
				vit = 2,
			},
			output_items = {
				"tek",
				"bar",
			},
		},
		rad_to_pow = {
			layout_order = 2,
			input_items = {
				rad = 1,
				bar = 1,
			},
			output_items = {
				"pow",
				"pow",
			},
		},
		tar_to_tek = {
			layout_order = 3,
			input_items = {
				tar = 2,
			},
			output_items = {
				"tek",
				"rad",
			},
		},
		bar_to_tek = {
			layout_order = 3,
			input_items = {
				bar = 4,
			},
			output_items = {
				"tek",
			},
		},
	},
	abilities = {},
	layer = entity_mod.LAYER.building,
}

return {}
