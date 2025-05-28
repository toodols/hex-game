local ReplicatedStorage = game:GetService "ReplicatedStorage"
local TweenService = game:GetService "TweenService"
local entity_mod = require(ReplicatedStorage.Client.entity)
local types = require(ReplicatedStorage.Shared.types)
local asset_server = require(ReplicatedStorage.Shared.asset_server)

type Entity = types.Entity & {
	head_rotation: number,
}
type World = types.World

entity_mod.registry.torch = entity_mod.with_defaults {
	model = asset_server.load "Entities/Torch",
	init = function(self: Entity, world: World)
		local instance = world.entity_instance_map[self.id]
		local head = instance:FindFirstChild "Head"
		head:PivotTo(CFrame.new(head:GetPivot().Position) * CFrame.Angles(0, self.head_rotation / 3 * math.pi, 0))
	end,
	update = function(self: Entity, world: World, old: Entity)
		local instance = world.entity_instance_map[self.id]
		local head = instance:FindFirstChild "Head"
		local cframe_value = Instance.new "CFrameValue"
		cframe_value.Value = head:GetPivot()
		local tween = TweenService:Create(cframe_value, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {
			Value = CFrame.new(head:GetPivot().Position) * CFrame.Angles(0, self.head_rotation / 3 * math.pi, 0),
		})
		tween:Play()
		cframe_value.Changed:Connect(function()
			head:PivotTo(cframe_value.Value)
		end)
	end,
}

return {}
