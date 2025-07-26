local ReplicatedStorage = game:GetService "ReplicatedStorage"
local coords = require(ReplicatedStorage.Shared.coords)
local asset_server = require(ReplicatedStorage.Shared.asset_server)
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local entity_mod = require(ReplicatedStorage.Client.entity)

local model = asset_server.load "Entities/Obelisk"

type World = types.World
type HexCell = types.HexCell
type Entity = types.Entity

function update_walls(self: Entity, world: World)
	local instance = world.entity_instance_map[self.id]
	util.set_transparency(instance:FindFirstChild "MeshPart", entity_mod.ENTITY_TRANSPARENCY[self.status])

	for _, neighbor_coord in (coords.neighbors_eq(self.primary_coordinate, 1)) do
		local neighbor_cell = world:get_cell(neighbor_coord)
		local neighbor_offset = coords.coords_sub(self.primary_coordinate, neighbor_coord)
		local vertex_instance = instance:FindFirstChild(("%d,%d,%d"):format(unpack(neighbor_offset)))
		if vertex_instance then
			local neighbor_vertex = world:query_entity({
				coordinate = neighbor_coord,
				type = "obelisk",
				owner = self.owner,
			})[1]
			util.set_transparency(
				vertex_instance,
				if neighbor_cell and neighbor_vertex then entity_mod.ENTITY_TRANSPARENCY[self.status] else 1
			)
		end
	end
end
entity_mod.registry.obelisk = entity_mod.with_defaults {
	model = model,
	update = function(self: Entity, world: World, old: Entity) end,
	status_changed = function(self, world)
		update_walls(self, world)
	end,
	neighbor_changed = function(self: Entity, world: World)
		update_walls(self, world)
	end,
	init = function(self: Entity, world: World)
		update_walls(self, world)
	end,
}

return {}
