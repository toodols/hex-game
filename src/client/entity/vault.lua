local ReplicatedStorage = game:GetService "ReplicatedStorage"
local registry_mod = require(script.Parent.registry)
local types = require(ReplicatedStorage.Shared.types)
local asset_server = require(ReplicatedStorage.Shared.asset_server)
local items_mod = require(ReplicatedStorage.Shared.items)

type Entity = types.Entity
type HexGrid = types.HexGrid

local model = asset_server.load "Entities/Vault"

function update_model(self: Entity, grid: HexGrid)
	local crystal = grid.entity_instance_map[self.id]:FindFirstChild "crystal" :: BasePart
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

registry_mod.registry["vault"] = registry_mod.with_defaults {
	model = model,
	update = function(self: Entity, grid: HexGrid, old: Entity)
		update_model(self, grid)
	end,
	animate = function(self: Entity, grid: HexGrid, animation_state: types.AnimationState)
		if not self.inventory then
			return
		end
		local instance_root = grid.entity_instance_map[self.id]
		if not instance_root then warn("no instance found for vault"); return end
		local t = (animation_state.step / 100) % (math.pi * 2)
		local instance = instance_root:FindFirstChild "crystal" :: BasePart
		local start = instance.Position
		instance:PivotTo(CFrame.Angles(0, t, 0) + start)
	end,
	init = function(self: Entity, grid: HexGrid)
		update_model(self, grid)
	end,
}

return {}
