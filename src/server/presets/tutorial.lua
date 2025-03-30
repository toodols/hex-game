local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local entity_mod = require(ServerScriptService.Server.entity)
local world_mod = require(ReplicatedStorage.Shared.world)
local turn_scheduler = require(ServerScriptService.Server.turn_scheduler)
local action_phase_mod = require(ServerScriptService.Server.action_phase)
type World = types.World
local tutorial_quest = require(ServerScriptService.Server.questing).tutorial

function tutorial_map()
	local world = world_mod.new_world_from_extents {
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
	world.speed_base = 1
	world.speed_multiplier = 0
	world.entity_configurations.extractor.power_input = 0
	world.entity_configurations.extractor.cycles_to_output = 1
	world.global_configuration.decaying_enabled = false

	world.turn_schedule = turn_scheduler.new_turn_schedule(function()
		turn_scheduler.reset_turn_time(world, world.turn_schedule)
		turn_scheduler.report_turn_time(world)
	end, function()
		action_phase_mod.run_action_phase(world)
	end)

	local player_team = world_mod.new_team(
		world,
		{},
		{ type = "color3", color = Color3.new(1, 0.392156, 0.392156) },
		"Player"
	)
	player_team.server_data.visibility = "perfect"
	world:get_cell({ -1, 0, 1 }).type = "bar_deposit"
	local extractor = entity_mod.new_entity({
		type = "extractor",
		primary_coordinate = { -1, 0, 1 },
		owner = player_team.id,
	}, world)
	local stockpile = entity_mod.new_entity({
		type = "stockpile",
		primary_coordinate = { 1, 0, -1 },
		owner = player_team.id,
	}, world)
	world.quests.tutorial = tutorial_quest(world)
	return world
end

return {
	tutorial_map = tutorial_map,
}
