local ServerScriptService = game:GetService "ServerScriptService"
local entity_mod = require(ServerScriptService.Server.entity)

entity_mod.registry.deposit = entity_mod.with_defaults {
	incorporeal = true,
	decayable = false,
	always_visible = true,
}

return {}
