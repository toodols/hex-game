local registry_mod = require(script.Parent.registry)
local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults

registry.vault = with_defaults {
	type = "vault",
	name = "Vault",
	description = "Stores up to <b>{entity.vault.inventory_capacity}</b> of the same item",
	max_health = 4,
	build_time = 0,
	inventory_capacity = 10,
	cost = {
		bar = 6,
		rad = 1,
	},
	required_research = {
		"vault",
	},
	can_capture = true,
	layer = registry_mod.layer.building,
}

return {}
