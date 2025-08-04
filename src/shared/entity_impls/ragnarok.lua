local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.ragnarok = entity_mod.with_defaults {
	type = "ragnarok",
	name = "Ragnarok",
	description = [[The Ragnarok is a rapid-fire long-range plasma cannon and is the ultimate weapon of mass-destruction.

    <b>It's a primary target once built, so be ready to defend it.</b>

It takes a lot of resources to build, but when it's ready you're almost guaranteed to win the match.]],
	short_description = "Rapid Fire Long Range Plasma Cannon",
	max_health = 30,
	build_time = 5,
	entity_group = {
		["@weapon"] = true,
	},
	cost = {
		pow = 20,
		bar = 10,
		rad = 10,
		tek = 10,
	},
	abilities = {
		attack = {
			type = "cannon",
			ignore_los = true,
			range = 8,
			damage = {
				amount = 1,
			},
			cost = {},
		},
		attack2 = {
			type = "cannon",
			ignore_los = true,
			range = 5,
			damage = {
				amount = 2,
			},
			cost = {},
		},
	},
	construction_condition = {
		nearby = { "turret" },
	},
	can_revive = true,
	layer = entity_mod.LAYER.building,
}

return {}
