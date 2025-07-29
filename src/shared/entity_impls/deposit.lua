local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.deposit = entity_mod.with_defaults {
	type = "deposit",
	name = "Any Deposit",
	description = "Deposit",
	max_health = math.huge,
	internal = true,
	buildable = false,
	layer = entity_mod.LAYER.deposit,
}

return {}
