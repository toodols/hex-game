local Debris = game:GetService "Debris"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Client.entity)
local types = require(ReplicatedStorage.Shared.types)
local asset_server = require(ReplicatedStorage.Shared.asset_server)
local util = require(ReplicatedStorage.Shared.util)
local coords = require(ReplicatedStorage.Shared.coords)

type Entity = types.Entity
type World = types.World

local model = asset_server.load "Entities/Calamity"
local indicator_template = asset_server.load "Effects/AttackArrow"

local function update_model(self: Entity, world: World, ability_id: string)
	local instance = world.entity_instance_map[self.id]
	local attack = util.table_find_pred(self.queued_decisions, function(v)
		return v.type == "ability" and v.ability_id == ability_id
	end)

	local indicator = instance:FindFirstChild(ability_id .. "AttackArrow")
	if attack then
		if not indicator then
			indicator = indicator_template:Clone()
			indicator.Name = ability_id .. "AttackArrow"
			indicator.Parent = instance
		end
		indicator:PivotTo(
			CFrame.lookAt(
				instance:GetPivot().Position,
				instance:GetPivot().Position
					+ coords.into_vec3(coords.coords_sub(attack.coordinate, self.primary_coordinate))
			)
		)
	else
		if indicator then
			indicator:Destroy()
		end
	end
end

entity_mod.registry.calamity = entity_mod.with_defaults {
	model = model,
	update = function(self: Entity, world: World, old: Entity)
		update_model(self, world, "attack")
		update_model(self, world, "attack2")
	end,
	init = function(self: Entity, world: World)
		update_model(self, world, "attack")
		update_model(self, world, "attack2")
	end,
	on_destroy = function(self: Entity, world: World)
		local instance: Instance = world.entity_instance_map[self.id]
		world.entity_instance_map[self.id] = nil
		world.instance_entity_map[instance] = nil
		Debris:AddItem(instance, 1)
	end,
}

return {}
