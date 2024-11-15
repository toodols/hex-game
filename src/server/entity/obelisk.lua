local registry_mod = require(script.Parent.registry)

registry_mod.registry.obelisk = registry_mod.with_defaults {
	autogenerate_wires = true,
}

return {}
