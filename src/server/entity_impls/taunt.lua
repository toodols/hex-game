local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local coords_mod = require(ReplicatedStorage.Shared.coords)
local entity_mod = require(ServerScriptService.Server.entity)
local damage_mod = require(ServerScriptService.Server.damage)
local util = require(ReplicatedStorage.Shared.util)

type Entity = types.Entity
type World = types.World
type EntityEvent = types.EntityEvent

entity_mod.registry.taunt = entity_mod.with_defaults {
	autogenerates_vertex = true,
	on_completed = function(self: Entity, world: World) end,
	influences = function(self: Entity, world: World)
		local config = world.entity_configurations[self.type]
		local neighbors = coords_mod.neighbors_leq(self.primary_coordinate, config.range)
		for _, coord in neighbors do
			if coords_mod.coords_eq(coord, self.primary_coordinate) then
				continue
			end
			local cell = world:get_cell(coord)
			if cell then
				if
					util.table_any(cell.entities, function(_, entity_id)
						return world.entities[entity_id].type == "taunt"
					end)
				then
					continue
				end
				cell.influences[self.id] = true
			end
		end
	end,
	on_event = function(self: Entity, world: World, event: EntityEvent)
		if event.entity_id == self.id and event.event_type == "killed" then
			local neighbors = coords_mod.neighbors_leq(self.primary_coordinate, 1)
			damage_mod.damage_cells(world, neighbors, {
				type = "physical",
				amount = 2,
				friendly_fire = true,
			})
		end
	end,
}

return {}
