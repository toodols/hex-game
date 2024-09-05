local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)
local registry_mod = require(script.Parent.registry)
local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults
local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)
local shared_entity_mod = require(ReplicatedStorage.Shared.entity)

local shared_behavior = shared_entity_mod.registry["generator"]

type Entity = types.Entity
type HexGrid = types.HexGrid
type ActionState = server_types.ActionState
registry["generator"] = with_defaults {
	autogenerate_wires = true,
	on_completed = function(self: Entity, grid: HexGrid) end,
	tick = function(self: Entity, grid: HexGrid, action_state: ActionState)
		if self.status == "complete" and self.owner ~= grid.neutral_team then
			table.insert(action_state.queue, {
				entity_id = self.id,
				type = "exchange",
				output_power = shared_behavior.output_power,
			})
		end
	end,
	influences = function(self: Entity, grid: HexGrid)
		local neighbors = hex_grid_mod.neighbors_leq(self.primary_coordinate, 1)
		for _, coord in neighbors do
			local cell = grid:get_cell(coord)
			if cell then
				cell.server_data.influences[self.id] = true
			end
		end
	end,
}

return {}
