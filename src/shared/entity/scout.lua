local registry_mod = require(script.Parent.registry)
local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults

registry["scout"] = with_defaults {
	type = "scout",
	name = "Scout",
	description = "Illuminates tiles and shoots enemies. Requires {entity.scout.abilities.scout_attack.cost} to shoot.",
	max_health = 3,
	build_time = 1,
	cost = {
		bar = 4,
	},
	abilities = {
		scout_attack = {
			range = 3,
			damage = 1,
			cost = {
				rad = 1,
			},
		},
	},
	can_capture = true,
	layer = registry_mod.layer.building,
}

return {}
