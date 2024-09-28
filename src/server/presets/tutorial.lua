local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local entity_mod = require(ServerScriptService.Server.entity)
local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)
type HexGrid = types.HexGrid
local tutorial_quest = require(ServerScriptService.Server.questing).tutorial

function tutorial_map()
	local grid = hex_grid_mod.new_grid_from_extents {
		{
			min = -1,
			max = 1,
		},
		{
			min = -1,
			max = 1,
		},
		{
			min = -1,
			max = 1,
		},
	}
	local player_team = grid:new_team({}, { type = "color3", color = Color3.new(1, 0.392156, 0.392156) }, "Player")
	local extractor = entity_mod.new_entity({
		type = "extractor",
		status = "complete",
		primary_coordinate = { -1, 0, 1 },
		owner = player_team.id,
	}, grid)
	local stockpile = entity_mod.new_entity({
		type = "stockpile",
		status = "complete",
		primary_coordinate = { 1, 0, -1 },
		owner = player_team.id,
	}, grid)
	grid.quests.tutorial = tutorial_quest(grid)
	return grid
end

return {
	tutorial_map = tutorial_map,
}
