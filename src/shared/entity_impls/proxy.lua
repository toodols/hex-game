local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.proxy = entity_mod.with_defaults {
	type = "proxy",
	name = "Proxy",
	description = "Extends the range of certain buildings with influence, such as {entity.sage}. Has a range of {entity.proxy.range}",
	range = 2,
	max_health = 3,
	build_time = 2,
	required_research = {
		"proxy",
	},
	cost = {
		rad = 1,
		bar = 2,
		vit = 1,
	},
	can_revive = true,
	layer = entity_mod.LAYER.building,
}

return {}
