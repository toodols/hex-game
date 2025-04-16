local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local entity_mod = require(ServerScriptService.Server.entity)
local types = require(ReplicatedStorage.Shared.types)

type Entity = types.Entity
type World = types.World

entity_mod.registry.barrier = entity_mod.with_defaults {
	decayable = false,
}

entity_mod.registry.impression = entity_mod.with_defaults {
	decayable = false,
}

entity_mod.registry.obelisk = entity_mod.with_defaults {
	autogenerates_vertex = true,
}

entity_mod.registry.phony = entity_mod.with_defaults {
	autogenerates_vertex = true,
}

entity_mod.registry.scout = entity_mod.with_defaults {
	autogenerates_vertex = true,
}

entity_mod.registry.turret = entity_mod.with_defaults {
	autogenerates_vertex = true,
}

entity_mod.registry.suggestion = entity_mod.with_defaults {
	decayable = false,
}

return {}
