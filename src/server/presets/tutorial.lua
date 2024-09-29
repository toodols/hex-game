local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local entity_mod = require(ServerScriptService.Server.entity)
local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)
local turn_scheduler = require(ServerScriptService.Server.turn_scheduler)
local action_phase_mod = require(ServerScriptService.Server.action_phase)
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
	grid.speed_base = 1
	grid.speed_multiplier = 0
	grid.entity_configurations.extractor.power_input = 0
	grid.entity_configurations.extractor.cycles_to_output = 1
	grid.global_configuration.decaying_enabled = false

	grid.turn_schedule = turn_scheduler.new_turn_schedule(function()
		turn_scheduler.reset_turn_time(grid, grid.turn_schedule)
		turn_scheduler.report_turn_time(grid)
	end, function()
		action_phase_mod.run_action_phase(grid)
	end)

	local player_team = grid:new_team({}, { type = "color3", color = Color3.new(1, 0.392156, 0.392156) }, "Player")
	player_team.server_data.visibility = "full"
	grid:get_cell({ -1, 0, 1 }).type = "bar_deposit"
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
