local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Client.entity)
local types = require(ReplicatedStorage.Shared.types)
local asset_server = require(ReplicatedStorage.Shared.asset_server)
local items_mod = require(ReplicatedStorage.Shared.items)
local RunService = game:GetService "RunService"
local get_deposit_type = require(ReplicatedStorage.Shared.deposit).get_deposit_type

type Entity = types.Entity
type World = types.World
type AnimationState = types.AnimationState
type EntityEvent = types.EntityEvent
entity_mod.registry.fountain = entity_mod.with_defaults {
	model = asset_server.load "Entities/Fountain",
	update = function(self: Entity, world: World)
		local deposit_type = get_deposit_type(world, self.primary_coordinate)
		local item_type
		if deposit_type == "bar_deposit" then
			item_type = "bar"
		elseif deposit_type == "vit_deposit" then
			item_type = "vit"
		elseif deposit_type == "rad_deposit" then
			item_type = "rad"
		elseif deposit_type == "tar_deposit" then
			item_type = "tar"
		end
		if item_type then
			local instance = world.entity_instance_map[self.id]
			if not instance then
				warn "no instance for fountain update"
			end
			local item = instance:FindFirstChild "Item"
			item.Color = items_mod.item_colors[item_type]
		end
	end,
	on_destroy = function(self: Entity, world: World, event: EntityEvent)
		assert(event.event_type == "destroy", "Not death event")
		local instance = world.entity_instance_map[self.id]
		if not instance then
			return
		end

		if event.death_type == "used" then
			local item = instance:FindFirstChild "Item"
			local item_p0 = instance:FindFirstChild "ItemP0"
			for _, v in instance:GetDescendants() do
				if v:IsA "BasePart" then
					v.Transparency = 0
				end
			end
			item_p0.Transparency = 1
			local step = 0
			local render_conn
			render_conn = RunService.RenderStepped:Connect(function()
				item.CFrame = item_p0.CFrame * CFrame.Angles(0, step / 20, 0) + Vector3.new(0, step / 100, 0)

				if step > 100 and step < 200 then
					local size_step = math.clamp(step - 100, 0, 100)
					item.Size = item_p0.Size * (1 + size_step / 100)
				end

				if step > 200 then
					local transparency_step = math.clamp(step - 200, 0, 70)
					item.Transparency = transparency_step / 70
					item.Size = item_p0.Size * 2 * (1 + transparency_step / 70) ^ 1.5
				end

				step += 1
				if step > 300 then
					render_conn:Disconnect()
					instance:Destroy()
				end
			end)
		else
			instance:Destroy()
		end
	end,
}

return {}
