local ServerScriptService = game:GetService "ServerScriptService"

local entity_mod = require(ServerScriptService.Server.entity)

entity_mod.registry.barrier = entity_mod.with_defaults {
	decayable = false,
}

entity_mod.registry.impression = entity_mod.with_defaults {
	decayable = false,
}

entity_mod.registry.obelisk = entity_mod.with_defaults {
	-- autogenerates_vertex = true,
	decayable = false,
}



entity_mod.registry.turret = entity_mod.with_defaults {
	autogenerates_vertex = true,
}

return {}
