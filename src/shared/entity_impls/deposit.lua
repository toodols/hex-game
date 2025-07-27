local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.deposit = entity_mod.with_defaults {
	type = "deposit",
	name = "Deposit",
	description = "Deposit",
	max_health = math.huge,
	hidden = true,
	buildable = false,
	layer = entity_mod.LAYER.deposit,
	abilities = {},
}

return {}
