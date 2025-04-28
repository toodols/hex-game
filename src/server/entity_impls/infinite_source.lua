local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)

local entity_mod = require(ServerScriptService.Server.entity)
local server_types = require(ServerScriptService.Server.types)

type Entity = types.Entity
type World = types.World
type ActionState = server_types.ActionState

entity_mod.registry.infinite_source = entity_mod.with_defaults {
	autogenerates_vertex = true,
	init = function(self: Entity, world: World)
	end,
	tick = function(self: Entity, world: World, action_state: ActionState) end,
}

return {}
