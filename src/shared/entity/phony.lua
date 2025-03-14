local registry_mod = require(script.Parent.registry)
local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults

registry.phony = with_defaults {
	type = "phony",
	name = "Phony",
	description = "Can disguise as a different building in a range of 4.",
	max_health = 3,
	build_time = 1,
	cost = {
		bar = 4,
	},
	abilities = {
		disguise = {
			range = 4,
		}
	},
	-- required_research = {
	-- 	"phony",
	-- },
	can_capture = true,
	layer = registry_mod.layer.building,
}

return {}
