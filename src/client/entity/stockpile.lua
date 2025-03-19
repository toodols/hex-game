local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"
local registry_mod = require(script.Parent.registry)
local asset_server = require(ReplicatedStorage.Shared.asset_server)
local types = require(ReplicatedStorage.Shared.types)
local items_mod = require(ReplicatedStorage.Shared.items)

type Entity = types.Entity
type World = types.World

function update_model(self: Entity, world: World)
	if self.status == "complete" then
		assert(self.inventory, "inventory nil")
		for i = 1, self.inventory.capacity do
			local instance = world.entity_instance_map[self.id]:FindFirstChild(tostring(i)) :: Part
			if self.inventory.items[i] then
				instance.Color = items_mod.item_colors[self.inventory.items[i]]
				instance.Transparency = 0
			else
				instance.Transparency = 1
			end
		end
	else
		for i = 1, math.huge do
			local instance = world.entity_instance_map[self.id]:FindFirstChild(tostring(i)) :: BasePart
			if not instance then
				break
			end
			instance.Transparency = 1
		end
	end
end

local model = asset_server.load "Entities/Stockpile"
registry_mod.registry.stockpile = registry_mod.with_defaults {
	model = model,
	status_changed = function(self: Entity, world: World, old: Entity)
		if self.status == "complete" then
			local instance = world.entity_instance_map[self.id]
			for _, v in instance:GetDescendants() do
				if v:IsA "BasePart" and not tonumber(v.Name) then
					(v :: BasePart).Transparency = 0
				end
			end
		end
	end,
	update = function(self: Entity, world: World, old: Entity)
		update_model(self, world)
	end,
	animate = function(self: Entity, world: World, animation_state: types.AnimationState)
		if not self.inventory then
			return
		end
		local instance_root = world.entity_instance_map[self.id]
		assert(instance_root, `instance_root of {self.id} is nil`)

		local t = (animation_state.step / 100) % (math.pi * 2)
		for i = 1, self.inventory.capacity do
			local t_i = ((i - 1) / self.inventory.capacity) * math.pi * 2 + t
			local instance = instance_root:FindFirstChild(tostring(i)) :: Part
			local x, y, z = math.sin(t_i), math.sin(t_i * 5) / 5, math.cos(t_i)
			instance.Position = world.entity_instance_map[self.id]:GetPivot().Position + Vector3.new(x, y + 1, z) * 1.5
		end
	end,
	init = function(self: Entity, world: World)
		update_model(self, world)
	end,
}

return {}
