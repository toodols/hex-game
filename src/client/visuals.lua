local TweenService = game:GetService "TweenService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Debris = game:GetService "Debris"
local types = require(ReplicatedStorage.Shared.types)
local asset_server = require(ReplicatedStorage.Shared.asset_server)
local util = require(ReplicatedStorage.Shared.util)
local items_mod = require(ReplicatedStorage.Shared.items)

type EntityEvent = types.EntityEvent
type Item = types.Item
type Entity = types.Entity
type HexCell = types.HexCell

function used_item_text(event: EntityEvent, adornee: Instance)
	local template = asset_server.load "Billboards/Exchange"
	local instance = template:Clone()
	instance.Parent = workspace
	instance.Adornee = adornee

	local function display(symbol: "+" | "-", items: { [Item]: number? }): string
		return table.concat(
			util.table_map(util.table_keys(items), function(k)
				return `{symbol}{items[k]} {items_mod.item_names[k]}`
			end),
			"\n"
		)
	end
	if event.event_type == "produced_items" then
		instance.Amount.Text = util.font(display("+", event.items), {
			color = Color3.fromRGB(163, 229, 160),
		})
	elseif event.event_type == "consumed_items" then
		instance.Amount.Text = util.font(display("-", event.items), {
			color = Color3.fromRGB(229, 107, 107),
		})
	else
		error "bad event type"
	end
	TweenService:Create(instance, TweenInfo.new(4), {
		StudsOffsetWorldSpace = Vector3.new(0, 4, 0),
	}):Play()
	TweenService:Create(instance.Amount, TweenInfo.new(4), {
		TextTransparency = 1,
	}):Play()
	Debris:AddItem(instance, 5)
end

function scout_attack_effect(entity_instance: PVInstance, cell_instance: PVInstance)
	local entity_pos = entity_instance:GetPivot().Position
	local cell_pos = cell_instance:GetPivot().Position
	local direction = math.atan2(entity_pos.Z - cell_pos.Z, entity_pos.X - cell_pos.X)

	local bullet_template = asset_server.load "Effects/Bullet"
	local bullet = bullet_template:Clone()
	bullet.Parent = workspace
	bullet.Position = entity_instance:GetPivot().Position

	local gun = entity_instance:FindFirstChild "Gun"
	local cframe_value = Instance.new "CFrameValue"
	cframe_value.Value = gun:GetPivot()
	local scout_tween = TweenService:Create(cframe_value, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {
		Value = CFrame.new(gun:GetPivot().Position) * CFrame.Angles(0, -direction, 0),
	})

	cframe_value.Changed:Connect(function()
		gun:PivotTo(cframe_value.Value)
	end)

	scout_tween:Play()
	scout_tween.Completed:Connect(function()
		local bullet_tween = TweenService:Create(bullet, TweenInfo.new(0.1, Enum.EasingStyle.Linear), {
			Position = Vector3.new(cell_pos.X, bullet.Position.Y, cell_pos.Z),
		})
		bullet_tween:Play()
		bullet_tween.Completed:Connect(function()
			TweenService:Create(bullet, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Transparency = 1,
				Color = Color3.fromRGB(200, 0, 0),
				Size = Vector3.new(4, 4, 4),
			}):Play()
			Debris:AddItem(bullet, 1)
		end)
	end)
end

function produced_item_effect(event: EntityEvent, origin: Vector3)
	assert(event.event_type == "produced_items", "Event is not produced_items")
	local item_template = asset_server.load "Effects/Item"
	for item_type, amount in event.items do
		for i = 1, amount do
			local item = item_template:Clone()
			item.Parent = workspace
			item.Position = origin + Vector3.new(0, 4, 0)
			item.Anchored = false

			item:ApplyImpulse(item:GetMass() * Vector3.new(math.random(-10, 10), 30, math.random(-10, 10)))
			item.Color = items_mod.item_colors[item_type]
			TweenService:Create(item, TweenInfo.new(2), {
				Transparency = 1,
			}):Play()
			Debris:AddItem(item, 2)
		end
	end
end

function consumed_item_effect(event: EntityEvent, origin: Vector3)
	assert(event.event_type == "consumed_items", "Event is not consumed_items")
	local item_template = asset_server.load "Effects/Item"
	task.spawn(function()
		for item_type, amount in event.items do
			for i = 1, amount do
				local item = item_template:Clone()
				item.Parent = workspace
				item.Position = origin + Vector3.new(0, 6, 0)
				item.Color = items_mod.item_colors[item_type]
				TweenService:Create(item, TweenInfo.new(0.7, Enum.EasingStyle.Quart), {
					Position = origin,
					Transparency = 1,
				}):Play()
				Debris:AddItem(item, 0.7)
				task.wait(0.2)
			end
		end
	end)
end

return {
	used_item_text = used_item_text,
	scout_attack_effect = scout_attack_effect,
	produced_item_effect = produced_item_effect,
	consumed_item_effect = consumed_item_effect,
}
