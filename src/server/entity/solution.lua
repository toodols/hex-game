local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)

local updates_mod = require(ServerScriptService.Server.updates)
local registry_mod = require(script.Parent.registry)

type Entity = types.Entity
type HexGrid = types.HexGrid
type EntityEvent = types.EntityEvent

registry_mod.registry.solution = registry_mod.with_defaults {
	init = function(self: Entity, grid: HexGrid)
		self.decayable = false
	end,
	abilities = {
		solution_use = function(self: Entity, grid: HexGrid)
			local config = grid.entity_configurations[self.type]
			for _, cell in
				util.table_filter_map(hex_grid_mod.neighbors_many_leq(self.coordinates, 1), function(coord)
					return grid:get_cell(coord)
				end)
			do
				for entity_id in cell.entities do
					local affected_entity = grid.entities[entity_id]
					-- it would be nice to use damage_mod for this but it doesn't support healing damage
					-- and this ignores layers
					affected_entity.health = math.max(
						affected_entity.max_health,
						affected_entity.health + config.abilities.solution_use.heal_amount
					)
					table.insert(affected_entity.effects, {
						type = "shield",
						health = config.abilities.solution_use.shield_health,
						duration = config.abilities.solution_use.shield_duration,
					})

					updates_mod.add_update(grid, {
						type = "entity_update",
						entity = affected_entity,
					})
				end
			end
		end,
	},
	on_event = function(self: Entity, grid: HexGrid, event: EntityEvent)
		if event.event_type == "killed" then
			registry_mod.registry[self.type].abilities.solution_use(self, grid)
		end
	end,
}

return {}
