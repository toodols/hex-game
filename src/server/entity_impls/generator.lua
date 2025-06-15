local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)
local coords = require(ReplicatedStorage.Shared.coords)
local entity_mod = require(ServerScriptService.Server.entity)

type Entity = types.Entity
type World = types.World
type ActionState = server_types.ActionState

entity_mod.registry.generator = entity_mod.with_defaults {
	autogenerates_vertex = true,
	on_completed = function(self: Entity, world: World) end,
	tick = function(self: Entity, world: World, action_state: ActionState)
		local config = world.entity_configurations[self.type]
		if self.status == "complete" and self.owner ~= world.capturable_team then
			table.insert(world.action_queue, {
				entity_id = self.id,
				type = "exchange",
				output_power = config.output_power,
			})
		end
	end,
	influences = function(self: Entity, world: World)
		local neighbors = coords.neighbors_leq(self.primary_coordinate, 1)
		for _, coord in neighbors do
			local cell = world:get_cell(coord)
			if cell then
				cell.influences[self.id] = true
			end
		end
	end,
}

return {}
