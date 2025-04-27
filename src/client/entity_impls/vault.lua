local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Client.entity)
local types = require(ReplicatedStorage.Shared.types)
local asset_server = require(ReplicatedStorage.Shared.asset_server)
local items_mod = require(ReplicatedStorage.Shared.items)

type Entity = types.Entity
type World = types.World

local model = asset_server.load "Entities/Vault"

function update_model(self: Entity, world: World)
	local crystal = world.entity_instance_map[self.id]:FindFirstChild "crystal" :: BasePart
	if self.status == "complete" then
		assert(self.inventory ~= nil, "inventory nil")
		if #self.inventory.items > 0 then
			local base_size = Vector3.new(0.351, 1.03, 0.351)
			local size_scale = math.pow(#self.inventory.items, 1 / 3)
			crystal.Size = base_size * size_scale
			crystal.Color = items_mod.item_colors[self.inventory.items[1]]
		else
			crystal.Transparency = 1
		end
	end
end

entity_mod.registry.vault = entity_mod.with_defaults {
	model = model,
	update = function(self: Entity, world: World, old: Entity)
		update_model(self, world)
	end,
	animate = function(self: Entity, world: World, animation_state: types.AnimationState)
		if not self.inventory then
			return
		end
		local instance_root = world.entity_instance_map[self.id]
		if not instance_root then
			warn "no instance found for vault"
			return
		end
		local t = (animation_state.step / 100) % (math.pi * 2)
		local instance = instance_root:FindFirstChild "crystal" :: BasePart
		local start = instance.Position
		instance:PivotTo(CFrame.Angles(0, t, 0) + start)
	end,
	init = function(self: Entity, world: World)
		update_model(self, world)
	end,
}

return {}
