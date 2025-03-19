local Debris = game:GetService "Debris"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local registry_mod = require(script.Parent.registry)
local types = require(ReplicatedStorage.Shared.types)
local asset_server = require(ReplicatedStorage.Shared.asset_server)
local util = require(ReplicatedStorage.Shared.util)
local coords = require(ReplicatedStorage.Shared.coords)

type Entity = types.Entity
type World = types.World

local model = asset_server.load "Entities/Turret"
local indicator_template = asset_server.load "Effects/AttackArrow"

local function update_model(self: Entity, world: World)
	local instance = world.entity_instance_map[self.id]
	local attack = util.table_find_pred(self.queued_decisions, function(v)
		return v.type == "ability" and v.ability_type == "turret_attack"
	end)

	local indicator = instance:FindFirstChild "AttackArrow"
	if attack then
		if not indicator then
			indicator = indicator_template:Clone()
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

registry_mod.registry.turret = registry_mod.with_defaults {
	model = model,
	update = function(self: Entity, world: World, old: Entity)
		update_model(self, world)
	end,
	init = function(self: Entity, world: World)
		update_model(self, world)
	end,
	on_destroy = function(self: Entity, world: World)
		local explosion = Instance.new "Explosion"
		explosion.DestroyJointRadiusPercent = 0
		explosion.BlastPressure = 0
		explosion.Parent = workspace
		explosion.Position = world.entity_instance_map[self.id]:GetPivot().Position
		Debris:AddItem(explosion, 1)
		Debris:AddItem(world.entity_instance_map[self.id], 1)
	end,
}

return {}
