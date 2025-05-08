local ReplicatedStorage = game:GetService "ReplicatedStorage"
local world_mod = require(ReplicatedStorage.Shared.world)
local types = require(ReplicatedStorage.Shared.types)
local coords = require(ReplicatedStorage.Shared.coords)

local entity_mod = require(script.Parent.entity)
local computed_mod = require(script.Parent.computed)
local updates_mod = require(script.Parent.updates)
local turn_scheduler = require(script.Parent.turn_scheduler)
local visibility_mod = require(script.Parent.visibility)
local systems = require(script.Parent.systems)
local tutorial_map = require(script.tutorial).tutorial_map
local testing_maps = require(script.testing)
local util = require(ReplicatedStorage.Shared.util)

type World = types.World
type TeamData = types.TeamData
type CubicCoordinate = types.CubicCoordinate

function my_map(): World
	-- Build the map
	local magic = 10

	local world = world_mod.new_world_from_extents {
		{ min = -magic, max = magic },
		{ min = -magic, max = magic },
		{ min = -magic, max = magic },
	}
	local team1 = world_mod.new_team(world, {}, { type = "color3", color = Color3.new(1, 0.392156, 0.392156) }, "Red")
	local team2 = world_mod.new_team(world, {}, { type = "color3", color = Color3.new(0.301960, 0.403921, 1) }, "Blue")

	turn_scheduler.bootstrap(world)

	local stockpile = entity_mod.new_entity({
		type = "stockpile",
		owner = team1.id,
		primary_coordinate = { magic - 1, -magic + 2, -1 },
	}, world)
	local _scout = entity_mod.new_entity({
		type = "scout",
		primary_coordinate = { magic - 2, -magic + 2, 0 },
		owner = team1.id,
	}, world)
	local _heart = entity_mod.new_entity({
		type = "heart",
		primary_coordinate = { magic - 1, -magic + 1, 0 },
		owner = team1.id,
	}, world)

	stockpile.inventory.items = { "bar", "rad", "rad", "bar", "bar" }

	local stockpile2 = entity_mod.new_entity({
		type = "stockpile",
		primary_coordinate = { -magic + 1, magic - 2, 1 },
		owner = team2.id,
	}, world)
	local _scout2 = entity_mod.new_entity({
		type = "scout",
		primary_coordinate = { 2 - magic, magic - 2, 0 },
		owner = team2.id,
	}, world)
	local _heart2 = entity_mod.new_entity({
		type = "heart",
		primary_coordinate = { 1 - magic, magic - 1, 0 },
		owner = team2.id,
	}, world)

	-- world:get_cell({ 1 - magic, magic - 1, 0 }).type = "bar_deposit"
	stockpile2.inventory.items = { "bar", "bar", "rad", "bar", "rad" }

	local shuffled_cells = {}
	for _, cell in world.cells do
		if cell.coordinate[1] > 0 then
			table.insert(shuffled_cells, cell)
		end
	end
	shuffled_cells = util.table_shuffle(shuffled_cells)

	local cell_count = #shuffled_cells
	local bar_deposit_quota = math.ceil(cell_count * 0.04 / 2)
	local vit_deposit_quota = math.ceil(cell_count * 0.015 / 2)
	local rad_deposit_quota = math.ceil(cell_count * 0.015 / 2)
	local tar_deposit_quota = math.ceil(cell_count * 0.015 / 2)
	local barrier_quota = math.ceil(cell_count * 0.2 / 2)

	local function inverse(coord: CubicCoordinate): CubicCoordinate
		return { -coord[1], -coord[2], -coord[3] }
	end

	local idx = 1

	for i = 1, bar_deposit_quota do
		local cell = shuffled_cells[idx]
		cell.type = "bar_deposit"
		local opp = world:get_cell(inverse(cell.coordinate))
		opp.type = "bar_deposit"
		idx += 1
	end
	for i = 1, vit_deposit_quota do
		local cell = shuffled_cells[idx]
		cell.type = "vit_deposit"
		local opp = world:get_cell(inverse(cell.coordinate))
		opp.type = "vit_deposit"
		idx += 1
	end
	for i = 1, rad_deposit_quota do
		local cell = shuffled_cells[idx]
		cell.type = "rad_deposit"
		local opp = world:get_cell(inverse(cell.coordinate))
		opp.type = "rad_deposit"
		idx += 1
	end
	for i = 1, tar_deposit_quota do
		local cell = shuffled_cells[idx]
		cell.type = "tar_deposit"
		local opp = world:get_cell(inverse(cell.coordinate))
		opp.type = "tar_deposit"
		idx += 1
	end
	for i = 1, barrier_quota do
		local cell = shuffled_cells[idx]
		if next(cell.entities) == nil then
			entity_mod.new_entity({
				type = "barrier",
				primary_coordinate = cell.coordinate,
				server_data = {
					always_visible = true,
					active = true,
				},
			}, world)
		end
		local cell2 = world:get_cell(inverse(cell.coordinate))
		if next(cell2.entities) == nil then
			entity_mod.new_entity({
				type = "barrier",
				primary_coordinate = cell2.coordinate,
				server_data = {
					always_visible = true,
					active = true,
				},
			}, world)
		end
		idx += 1
	end

	local origin = world:get_cell { 0, 0, 0 }
	origin.type = "bar_deposit"

	return world, {
		team1 = team1,
		team2 = team2,
	}
end

function lightning()
	local world, teams = my_map()
	world.speed_base = 6
	world.speed_multiplier = 0.01
	return world, teams
end

function prepare_preset(fn: (...any) -> World): (...any) -> (World, { [string]: TeamData })
	return function(...)
		local result = { fn(...) }
		local world = result[1]
		updates_mod.flush_updates(world)
		computed_mod.compute_presence(world)
		visibility_mod.compute_visibility(world)
		systems.compute_systems(world)
		return unpack(result)
	end
end

return {
	tutorial_map = prepare_preset(tutorial_map),
	lightning = prepare_preset(lightning),
	my_map = prepare_preset(my_map),
	all_entities = prepare_preset(testing_maps.all_entities),
	blank_map = prepare_preset(testing_maps.blank_map),
	stress_test = prepare_preset(testing_maps.stress_test),
	map_with_infinite_source = prepare_preset(testing_maps.map_with_infinite_source),
}
