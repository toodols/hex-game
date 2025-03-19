local ReplicatedStorage = game:GetService "ReplicatedStorage"
local registry_mod = require(script.Parent.registry)
local types = require(ReplicatedStorage.Shared.types)
local asset_server = require(ReplicatedStorage.Shared.asset_server)

type Entity = types.Entity
type World = types.World

local model = asset_server.load "Entities/Factory"

registry_mod.registry.factory = registry_mod.with_defaults {
	model = model,
	update = function(self: Entity, world: World, old: Entity) end,
	init = function(self: Entity, world: World) end,
}

return {}
