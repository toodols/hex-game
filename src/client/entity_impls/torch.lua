local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Client.entity)
local types = require(ReplicatedStorage.Shared.types)
local asset_server = require(ReplicatedStorage.Shared.asset_server)

type Entity = types.Entity
type World = types.World

entity_mod.registry.torch = entity_mod.with_defaults {
	model = asset_server.load "Entities/Torch",
	update = function(self: Entity, world: World, old: Entity)
		local instance = world.entity_instance_map[self.id]
		instance:PivotTo(
			CFrame.new(instance:GetPivot().Position) * CFrame.Angles(0, math.rad(self.rotation / 3 * math.pi), 0)
		)
	end,
}

return {}
