local registry_mod = require(script.Parent.registry)
local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults

registry["proxy"] = with_defaults {
	type = "proxy",
	name = "Proxy",
	description = "Extends the range of {entity.laboratory}. Has a range of {entity.proxy.range}",
	range = 3,
	max_health = 3,
	build_time = 2,
	required_research = {
		"proxy",
	},
	cost = {
		rad = 2,
	},
	layer = registry_mod.layer.building,
}

return {}
