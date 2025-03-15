local ReplicatedStorage = game:GetService "ReplicatedStorage"
local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)
local entity_mod = require(script.Parent.entity)
local computed_mod = require(script.Parent.computed)
local types = require(ReplicatedStorage.Shared.types)
local updates_mod = require(script.Parent.updates)
local turn_scheduler = require(script.Parent.turn_scheduler)
local action_phase_mod = require(script.Parent.action_phase)
local tutorial_map = require(script.tutorial).tutorial_map
local testing_maps = require(script.testing)

type HexGrid = types.HexGrid

function my_map(): HexGrid
	-- Build the map
	local magic = 5

	local grid = hex_grid_mod.new_grid_from_extents {
		{ min = -magic, max = magic },
		{ min = -magic, max = magic },
		{ min = -magic, max = magic },
	}
	local team1 = grid:new_team({}, { type = "color3", color = Color3.new(1, 0.392156, 0.392156) }, "Red")
	local team2 = grid:new_team({}, { type = "color3", color = Color3.new(0.301960, 0.403921, 1) }, "Blue")

	grid.turn_schedule = turn_scheduler.new_turn_schedule(function()
		turn_scheduler.reset_turn_time(grid, grid.turn_schedule)
		turn_scheduler.report_turn_time(grid)
	end, function()
		action_phase_mod.run_action_phase(grid)
	end)
	turn_scheduler.reset_turn_time(grid, grid.turn_schedule)
	turn_scheduler.turn_schedule_resume(grid.turn_schedule)

	for _, cell in grid.cells do
		if math.random() < 0.0015 then
			grid:get_cell(hex_grid_mod.coords_sub({ 0, 0, 0 }, cell.coordinate)).type = "vit_deposit"
			cell.type = "vit_deposit"
		elseif math.random() < 0.003 then
			grid:get_cell(hex_grid_mod.coords_sub({ 0, 0, 0 }, cell.coordinate)).type = "rad_deposit"
			cell.type = "rad_deposit"
		elseif math.random() < 0.0045 then
			grid:get_cell(hex_grid_mod.coords_sub({ 0, 0, 0 }, cell.coordinate)).type = "tar_deposit"
			cell.type = "tar_deposit"
		elseif math.random() < 0.008 then
			cell.type = "bar_deposit"
			grid:get_cell(hex_grid_mod.coords_sub({ 0, 0, 0 }, cell.coordinate)).type = "bar_deposit"
		end
	end

	for _, coord in
		{
			{ 1, -1, 0 },
			{ -1, 1, 0 },
			{ 0, -5, 5 },
			{ 0, -4, 4 },
			{ 0, 4, -4 },
			{ 0, 5, -5 },
			{ -4, 0, 4 },
			{ 4, 0, -4 },
			{ 5, 0, -5 },
			{ -5, 0, 5 },
		}
	do
		entity_mod.new_entity({
			type = "barrier",
			status = "complete",
			primary_coordinate = coord,
			server_data = {
				always_visible = true,
			},
		}, grid)
	end

	-- local portals = { { { -5, 5, 0 }, { 5, -5, 0 } } }
	-- for _, portal_group in portals do
	-- 	for _, portal in portal_group do
	-- 		local cell = grid:get_cell(portal)
	-- 		cell.type = "portal"
	-- 		cell.portal = {
	-- 			group = portal_group,
	-- 			open = false,
	-- 			open_time = 5,
	-- 			close_time = 5,
	-- 			steps = 0,
	-- 		}
	-- 	end
	-- end

	grid:get_cell({ 0, 0, 0 }).type = "bar_deposit"
	grid:get_cell({ 0, -2, 2 }).type = "rad_deposit"
	grid:get_cell({ 0, 2, -2 }).type = "rad_deposit"
	grid:get_cell({ 2, 0, -2 }).type = "vit_deposit"
	grid:get_cell({ -2, 0, 2 }).type = "vit_deposit"
	grid:get_cell({ magic, 0, -magic }).type = "bar_deposit"
	grid:get_cell({ -magic, 0, magic }).type = "bar_deposit"

	-- local extractor = entity_mod.new_entity({
	-- 	type = "extractor",
	-- 	status = "complete",
	-- 	primary_coordinate = { magic - 1, -magic + 1, 0 },
	-- 	owner = team1.id,
	-- }, grid)
	local stockpile = entity_mod.new_entity({
		type = "stockpile",
		status = "complete",
		owner = team1.id,
		primary_coordinate = { magic - 1, -magic + 2, -1 },
	}, grid)
	local scout = entity_mod.new_entity({
		type = "scout",
		status = "complete",
		primary_coordinate = { magic - 2, -magic + 2, 0 },
		owner = team1.id,
	}, grid)
	local heart = entity_mod.new_entity({
		type = "heart",
		status = "complete",
		primary_coordinate = { magic - 1, -magic + 1, 0 },
		owner = team1.id,
	}, grid)

	stockpile.inventory.items = { "bar", "rad", "rad", "bar", "bar" }

	-- grid:get_cell({ magic - 1, -magic + 1, 0 }).type = "bar_deposit"

	-- local extractor2 = entity_mod.new_entity({
	-- 	type = "extractor",
	-- 	status = "complete",
	-- 	primary_coordinate = { 1 - magic, magic - 1, 0 },
	-- 	owner = team2.id,
	-- }, grid)

	local stockpile2 = entity_mod.new_entity({
		type = "stockpile",
		status = "complete",
		primary_coordinate = { -magic + 1, magic - 2, 1 },
		owner = team2.id,
	}, grid)
	local scout2 = entity_mod.new_entity({
		type = "scout",
		status = "complete",
		primary_coordinate = { 2 - magic, magic - 2, 0 },
		owner = team2.id,
	}, grid)
	local heart2 = entity_mod.new_entity({
		type = "heart",
		status = "complete",
		primary_coordinate = { 1 - magic, magic - 1, 0 },
		owner = team2.id,
	}, grid)

	-- grid:get_cell({ 1 - magic, magic - 1, 0 }).type = "bar_deposit"
	stockpile2.inventory.items = { "bar", "bar", "rad", "bar", "rad" }

	return grid
end

function prepare_preset(fn: (...any) -> HexGrid): (...any) -> HexGrid
	return function(...)
		local result = { fn(...) }
		local grid = result[1]
		updates_mod.flush_updates(grid)
		computed_mod.compute_presence(grid)
		computed_mod.compute_visibility(grid)
		computed_mod.compute_systems(grid)
		return unpack(result)
	end
end

return {
	tutorial_map = prepare_preset(tutorial_map),
	my_map = prepare_preset(my_map),
	all_entities = prepare_preset(testing_maps.all_entities),
	blank_map = prepare_preset(testing_maps.blank_map),
}
