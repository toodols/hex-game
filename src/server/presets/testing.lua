local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local world_mod = require(ReplicatedStorage.Shared.world)
local coords = require(ReplicatedStorage.Shared.coords)
local turn_scheduler = require(ServerScriptService.Server.turn_scheduler)
local entity_mod = require(ServerScriptService.Server.entity)

type World = types.World

-- A bunch of entities lined up
function all_entities(): World
	local world = world_mod.new_world_from_extents {
		{ min = -10, max = 10 },
		{ min = -10, max = 10 },
		{ min = -3, max = 3 },
	}

	local team1 = world_mod.new_team(world, {}, { type = "color3", color = Color3.new(1, 0.392156, 0.392156) }, "red")
	team1.server_data.visibility = "perfect"
	local team2 = world_mod.new_team(world, {}, { type = "color3", color = Color3.new(0.301960, 0.403921, 1) }, "blue")
	team2.is_player_team = false

	local start = { -9, 7, 2 }

	local function next_entity(ty: string)
		local entity = entity_mod.new_entity({
			type = ty,
			primary_coordinate = start,
			owner = team1.id,
		}, world)
		start = {
			start[1] + 1,
			start[2] - 1,
			start[3],
		}
		return entity
	end

	world.cells[coords.encode_coord(start)].type = "bar_deposit"

	for _, ty in
		{
			"extractor",
			"stockpile",
			"scout",
			"witness",
			"heart",
			"laboratory",
			"vault",
			"proxy",
			"barrier",
			"solution",
			"impression",
			"suggestion",
			"turret",
			"factory",
			"infinite_source",
		}
	do
		next_entity(ty)
	end

	return world
end

function map_with_infinite_source()
	local world = world_mod.new_world_from_extents {
		{ min = -10, max = 10 },
		{ min = -10, max = 10 },
		{ min = -10, max = 10 },
	}
	local team1 = world_mod.new_team(world, {}, { type = "color3", color = Color3.new(1, 0.392156, 0.392156) }, "red")
	local team2 = world_mod.new_team(world, {}, { type = "color3", color = Color3.new(0.301960, 0.403921, 1) }, "blue")

	entity_mod.new_entity({
		type = "infinite_source",
		primary_coordinate = { 0, 0, 0 },
		owner = team1.id,
	}, world)

	turn_scheduler.bootstrap(world)
	return world
end

-- empty world with 2 teams
function blank_map(magic: number): World
	magic = magic or 4
	local world = world_mod.new_world_from_extents {
		{ min = -5, max = 5 },
		{ min = -5, max = 5 },
		{ min = -5, max = 5 },
	}

	local team1 = world_mod.new_team(world, {}, { type = "color3", color = Color3.new(1, 0.392156, 0.392156) }, "red")
	local team2 = world_mod.new_team(world, {}, { type = "color3", color = Color3.new(0.301960, 0.403921, 1) }, "blue")

	return world, {
		team1 = team1,
		team2 = team2,
	}
end

function stress_test(): World
	local world = world_mod.new_world_from_extents {
		{ min = -20, max = 20 },
		{ min = -20, max = 20 },
		{ min = -20, max = 20 },
	}
	world.global_configuration.decaying_enabled = false
	local team1 = world_mod.new_team(world, {}, { type = "color3", color = Color3.new(1, 0.392156, 0.392156) }, "Red")

	for encoded_coord, cell in world.cells do
		local x, y, z = unpack(cell.coordinate)
		if (x + y) % 2 == 0 then
			cell.type = "bar_deposit"
			entity_mod.new_entity({
				type = "extractor",
				primary_coordinate = cell.coordinate,
				owner = team1.id,
			}, world)
		else
			entity_mod.new_entity({
				type = "stockpile",
				primary_coordinate = cell.coordinate,
				owner = team1.id,
			}, world)
		end
	end

	turn_scheduler.bootstrap(world)
	return world
end

return {
	all_entities = all_entities,
	blank_map = blank_map,
	stress_test = stress_test,
	map_with_infinite_source = map_with_infinite_source,
}
