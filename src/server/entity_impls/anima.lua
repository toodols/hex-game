local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local entity_mod = require(ServerScriptService.Server.entity)
local server_types = require(ServerScriptService.Server.types)

type Entity = types.Entity
type World = types.World

entity_mod.registry.anima = entity_mod.with_defaults {
	autogenerates_vertex = true,
}

return {}
