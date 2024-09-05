local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local types = require(ReplicatedStorage.Shared.types)
local registry_mod = require(script.Parent.registry)
local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)
local server_types = require(ServerScriptService.Server.types)
local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults
local shared_entity_mod = require(ReplicatedStorage.Shared.entity)
local shared_behavior = shared_entity_mod.registry["proxy"]

type Entity = types.Entity
type HexGrid = types.HexGrid
type ActionState = server_types.ActionState

registry["proxy"] = with_defaults {
	autogenerate_wires = true,
	on_completed = function(self: Entity, grid: HexGrid) end,
	on_research_complete = function(self: Entity, grid: HexGrid, research_id: string) end,
	influences = function(self: Entity, grid: HexGrid)
		local neighbors = hex_grid_mod.neighbors_leq(self.primary_coordinate, shared_behavior.range)
		for _, coord in neighbors do
			local cell = grid:get_cell(coord)
			if cell then
				cell.server_data.influences[self.id] = true
			end
		end
	end,
}

return {}
