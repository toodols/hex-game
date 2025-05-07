local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)
local util = require(ReplicatedStorage.Shared.util)
local entity_mod = require(ServerScriptService.Server.entity)

local updates_mod = require(ServerScriptService.Server.updates)

type Entity = types.Entity
type EntityId = types.EntityId
type HexCell = types.HexCell
type CubicCoordinate = types.CubicCoordinate
type World = types.World
type ActionState = server_types.ActionState

entity_mod.registry.vertex = entity_mod.with_defaults {
	on_completed = function(self: Entity, world: World)
		-- Capturing mechanics: if this entity is not neutral, and is built on a cell that has neutral entities,
		-- neutral entities are captured, neutral vertex are destroyed
		if self.owner == world.neutral_team then
			return
		end
		local cell = world:get_cell(self.primary_coordinate)
		for entity_id in cell.entities do
			local entity = world.entities[entity_id]
			if entity.owner == world.neutral_team then
				if entity.type == "vertex" then
					error "there should not be a neutral vertex"
				end
				entity.owner = self.owner
				world:add_update { type = "entity_update", entity = entity }
			end
		end
	end,
}

return {}
