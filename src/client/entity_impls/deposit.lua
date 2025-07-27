local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Client.entity)
local types = require(ReplicatedStorage.Shared.types)
local asset_server = require(ReplicatedStorage.Shared.asset_server)
local coords = require(ReplicatedStorage.Shared.coords)

type Entity = types.Entity
type World = types.World
type AnimationState = types.AnimationState
type EntityEvent = types.EntityEvent

local bar_model = asset_server.load "Entities/BarDeposit"
local rad_model = asset_server.load "Entities/RadDeposit"
local vit_model = asset_server.load "Entities/VitDeposit"
local tar_model = asset_server.load "Entities/TarDeposit"

entity_mod.registry.deposit = entity_mod.with_defaults {
	create_model = function(entity: Entity?, world: World)
		if entity == nil then
			return bar_model:Clone()
		end
		local instance = if entity.deposit_type == "bar_deposit"
			then bar_model:Clone()
			elseif entity.deposit_type == "rad_deposit" then rad_model:Clone()
			elseif entity.deposit_type == "vit_deposit" then vit_model:Clone()
			elseif entity.deposit_type == "tar_deposit" then tar_model:Clone()
			else error "unreachable"

		local cell_instance = world.cell_instance_map[coords.encode_coord(entity.primary_coordinate)]
		instance:PivotTo(
			(cell_instance.Base.CFrame + Vector3.new(0, cell_instance.Base.Size.Y / 2, 0))
				* CFrame.Angles(0, math.pi / 3 * entity.rotation, 0)
		)
		return instance
	end,
	update = function(self: Entity, world: World) end,
}

return {}
