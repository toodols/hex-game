local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Client.entity)
local types = require(ReplicatedStorage.Shared.types)
local asset_server = require(ReplicatedStorage.Shared.asset_server)
local items_mod = require(ReplicatedStorage.Shared.items)
local RunService = game:GetService "RunService"

type Entity = types.Entity
type World = types.World
type AnimationState = types.AnimationState
type EntityEvent = types.EntityEvent

entity_mod.registry.phony = entity_mod.with_defaults {
	model = asset_server.load "Entities/Phony",
	update = function(self: Entity, world: World)
		local instance = world.entity_instance_map[self.id]
		if instance == nil then
			return
		end
		if self.disguise ~= nil then
			instance:FindFirstChild("Hidden"):FindFirstChild("ParticleEmitter").Enabled = true
		else
			instance:FindFirstChild("Hidden"):FindFirstChild("ParticleEmitter").Enabled = false
		end
	end,
	animate = function(self: Entity, world: World, animation_state: AnimationState)
		if self.status ~= "complete" then
			return
		end
		local instance = world.entity_instance_map[self.id]
		assert(instance, "instance not found for entity " .. self.id .. " of type " .. self.type)
		local spin = instance:FindFirstChild "Spin"
		if animation_state.type == "idle" then
			local t = animation_state.step % (math.pi * 2)
			spin:PivotTo(instance:GetPivot() * CFrame.Angles(0, t, 0) + Vector3.new(0, 1.5, 0))
		end
	end,
}

return {}
