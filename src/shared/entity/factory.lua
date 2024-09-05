local registry_mod = require(script.Parent.registry)
local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults

registry["factory"] = with_defaults {
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
			input_power = 1,
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
			input_power = 1,
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
			input_power = 1,
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
			input_power = 1,
			input_items = {
				bar = 4,
			},
			output_items = {
				"tek",
			},
		},
	},
	abilities = {},
	layer = registry_mod.layer.building,
}

return {}
