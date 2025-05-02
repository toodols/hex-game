local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local entity_mod = require(ServerScriptService.Server.entity)
local types = require(ReplicatedStorage.Shared.types)
local coords = require(ReplicatedStorage.Shared.coords)
local server_types = require(ServerScriptService.Server.types)

type Entity = types.Entity
type World = types.World
type ActionState = server_types.ActionState

entity_mod.registry.proxy = entity_mod.with_defaults {
	autogenerates_vertex = true,
	on_completed = function(self: Entity, world: World) end,
}

return {}
