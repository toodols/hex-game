local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.taunt = entity_mod.with_defaults {
	type = "taunt",
	name = "Taunt",
	description = [[Enemy buildings in a range of {entity.taunt.range} who can see this building:
	- Must target {entity.taunt} if possible
On death:
- Building that killed this gains immunity to taunt

]],
	short_description = "Draws enemy fire towards itself",
	max_health = 4,
	build_time = 2,
	cost = {
		pow = 1,
		bar = 4,
	},
	range = 3,
	construction_condition = {
		nearby = { "turret" },
	},
	can_revive = true,
	layer = entity_mod.LAYER.building,
}

return {}
