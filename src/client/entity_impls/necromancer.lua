local ReplicatedStorage = game:GetService "ReplicatedStorage"
local asset_server = require(ReplicatedStorage.Shared.asset_server)
local types = require(ReplicatedStorage.Shared.types)
local entity_mod = require(ReplicatedStorage.Client.entity)
local coords = require(ReplicatedStorage.Shared.coords)

type World = types.World
type HexCell = types.HexCell
type Entity = types.Entity

entity_mod.registry.necromancer = entity_mod.with_defaults {
	model = asset_server.load "Entities/Necromancer",
}

local grave = asset_server.load "Entities/Grave"

entity_mod.registry.grave = entity_mod.with_defaults {
	-- model = asset_server.load "Entities/Grave",
	create_model = function(entity: Entity?, world: World)
		local instance = grave:Clone()
		if entity then
			local cell_instance = world.cell_instance_map[coords.encode_coord(entity.primary_coordinate)]
			instance:PivotTo(
				(cell_instance.Base.CFrame + Vector3.new(0, cell_instance.Base.Size.Y / 2, 0))
					* CFrame.Angles(0, math.pi / 3 * entity.rotation, 0)
			)
		end
		return instance
	end,
}

return {}
