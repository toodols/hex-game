local ReplicatedStorage = game:GetService "ReplicatedStorage"
local world_mod = require(ReplicatedStorage.Shared.world)
local types = require(ReplicatedStorage.Shared.types)
local coords = require(ReplicatedStorage.Shared.coords)

local entity_mod = require(script.Parent.entity)
local computed_mod = require(script.Parent.computed)
local updates_mod = require(script.Parent.updates)
local turn_scheduler = require(script.Parent.turn_scheduler)
local action_phase_mod = require(script.Parent.action_phase)
local visibility_mod = require(script.Parent.visibility)
local tutorial_map = require(script.tutorial).tutorial_map
local testing_maps = require(script.testing)

type World = types.World

function my_map(): World
	-- Build the map
	local magic = 10

	local world = world_mod.new_world_from_extents {
		{ min = -magic, max = magic },
		{ min = -magic, max = magic },
		{ min = -magic, max = magic },
	}
	local team1 = world:new_team({}, { type = "color3", color = Color3.new(1, 0.392156, 0.392156) }, "Red")
	local team2 = world:new_team({}, { type = "color3", color = Color3.new(0.301960, 0.403921, 1) }, "Blue")

	world.turn_schedule = turn_scheduler.new_turn_schedule(function()
		turn_scheduler.reset_turn_time(world, world.turn_schedule)
		turn_scheduler.report_turn_time(world)
	end, function()
		action_phase_mod.run_action_phase(world)
	end)
	turn_scheduler.reset_turn_time(world, world.turn_schedule)
	turn_scheduler.turn_schedule_resume(world.turn_schedule)

	for _, cell in world.cells do
		if math.random() < 0.0015 then
			world:get_cell(coords.coords_sub({ 0, 0, 0 }, cell.coordinate)).type = "vit_deposit"
			cell.type = "vit_deposit"
		elseif math.random() < 0.003 then
			world:get_cell(coords.coords_sub({ 0, 0, 0 }, cell.coordinate)).type = "rad_deposit"
			cell.type = "rad_deposit"
		elseif math.random() < 0.0045 then
			world:get_cell(coords.coords_sub({ 0, 0, 0 }, cell.coordinate)).type = "tar_deposit"
			cell.type = "tar_deposit"
		elseif math.random() < 0.008 then
			cell.type = "bar_deposit"
			world:get_cell(coords.coords_sub({ 0, 0, 0 }, cell.coordinate)).type = "bar_deposit"
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
			primary_coordinate = coord,
			server_data = {
				always_visible = true,
				active = true,
			},
		}, world)
	end

	-- local portals = { { { -5, 5, 0 }, { 5, -5, 0 } } }
	-- for _, portal_group in portals do
	-- 	for _, portal in portal_group do
	-- 		local cell = world:get_cell(portal)
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

	world:get_cell({ 0, 0, 0 }).type = "bar_deposit"
	world:get_cell({ 0, -2, 2 }).type = "rad_deposit"
	world:get_cell({ 0, 2, -2 }).type = "rad_deposit"
	world:get_cell({ 2, 0, -2 }).type = "vit_deposit"
	world:get_cell({ -2, 0, 2 }).type = "vit_deposit"
	world:get_cell({ magic, 0, -magic }).type = "bar_deposit"
	world:get_cell({ -magic, 0, magic }).type = "bar_deposit"

	-- local extractor = entity_mod.new_entity({
	-- 	type = "extractor",
	-- 	primary_coordinate = { magic - 1, -magic + 1, 0 },
	-- 	owner = team1.id,
	-- }, world)
	local stockpile = entity_mod.new_entity({
		type = "stockpile",
		owner = team1.id,
		primary_coordinate = { magic - 1, -magic + 2, -1 },
	}, world)
	local scout = entity_mod.new_entity({
		type = "scout",
		primary_coordinate = { magic - 2, -magic + 2, 0 },
		owner = team1.id,
	}, world)
	local heart = entity_mod.new_entity({
		type = "heart",
		primary_coordinate = { magic - 1, -magic + 1, 0 },
		owner = team1.id,
	}, world)

	stockpile.inventory.items = { "bar", "rad", "rad", "bar", "bar" }

	-- world:get_cell({ magic - 1, -magic + 1, 0 }).type = "bar_deposit"

	-- local extractor2 = entity_mod.new_entity({
	-- 	type = "extractor",
	-- 	primary_coordinate = { 1 - magic, magic - 1, 0 },
	-- 	owner = team2.id,
	-- }, world)

	local stockpile2 = entity_mod.new_entity({
		type = "stockpile",
		primary_coordinate = { -magic + 1, magic - 2, 1 },
		owner = team2.id,
	}, world)
	local scout2 = entity_mod.new_entity({
		type = "scout",
		primary_coordinate = { 2 - magic, magic - 2, 0 },
		owner = team2.id,
	}, world)
	local heart2 = entity_mod.new_entity({
		type = "heart",
		primary_coordinate = { 1 - magic, magic - 1, 0 },
		owner = team2.id,
	}, world)

	-- world:get_cell({ 1 - magic, magic - 1, 0 }).type = "bar_deposit"
	stockpile2.inventory.items = { "bar", "bar", "rad", "bar", "rad" }

	return world
end

function prepare_preset(fn: (...any) -> World): (...any) -> World
	return function(...)
		local result = { fn(...) }
		local world = result[1]
		updates_mod.flush_updates(world)
		computed_mod.compute_presence(world)
		visibility_mod.compute_visibility(world)
		computed_mod.compute_systems(world)
		return unpack(result)
	end
end

return {
	tutorial_map = prepare_preset(tutorial_map),
	my_map = prepare_preset(my_map),
	all_entities = prepare_preset(testing_maps.all_entities),
	blank_map = prepare_preset(testing_maps.blank_map),
	stress_test = prepare_preset(testing_maps.stress_test),
}
