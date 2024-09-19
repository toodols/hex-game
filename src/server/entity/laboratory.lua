local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local types = require(ReplicatedStorage.Shared.types)
local registry_mod = require(script.Parent.registry)
local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)
local server_types = require(ServerScriptService.Server.types)
local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults
local researches_mod = require(ReplicatedStorage.Shared.researches)

type Entity = types.Entity
type HexGrid = types.HexGrid
type ActionState = server_types.ActionState

registry["laboratory"] = with_defaults {
	autogenerate_wires = true,
	on_completed = function(self: Entity, grid: HexGrid) end,
	on_research_complete = function(self: Entity, grid: HexGrid, research_id: string) end,
	tick = function(self: Entity, grid: HexGrid, action_state: ActionState)
		if self.status == "complete" and self.owner ~= grid.neutral_team then
			table.insert(action_state.queue, {
				type = "advance_research",
				entity_id = self.id,
			})
		end
	end,
	influences = function(self: Entity, grid: HexGrid)
		local config = grid.entity_configurations[self.type]
		local neighbors = hex_grid_mod.neighbors_leq(self.primary_coordinate, config.range)
		for _, coord in neighbors do
			local cell = grid:get_cell(coord)
			if cell then
				cell.server_data.influences[self.id] = true
			end
		end
	end,
	init = function(self: Entity, grid: HexGrid)
		self.researches = {
			queue = {},
			states = researches_mod.create_researches(),
		}
	end,
}

return {}
