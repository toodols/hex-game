local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local world_mod = require(ReplicatedStorage.Shared.world)
local entity_mod = require(ServerScriptService.Server.entity)
local coords = require(ReplicatedStorage.Shared.coords)

type World = types.World

-- A bunch of entities lined up
function all_entities(): World
	local world = world_mod.new_world_from_extents {
		{ min = -10, max = 10 },
		{ min = -10, max = 10 },
		{ min = -3, max = 3 },
	}

	local team1 = world:new_team({}, { type = "color3", color = Color3.new(1, 0.392156, 0.392156) }, "red")
	team1.server_data.visibility = "perfect"
	local team2 = world:new_team({}, { type = "color3", color = Color3.new(0.301960, 0.403921, 1) }, "blue")
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

-- 10x10x10 empty world with 2 teams
function blank_map(): World
	local world = world_mod.new_world_from_extents {
		{ min = -10, max = 10 },
		{ min = -10, max = 10 },
		{ min = -10, max = 10 },
	}

	local team1 = world:new_team({}, { type = "color3", color = Color3.new(1, 0.392156, 0.392156) }, "red")
	local team2 = world:new_team({}, { type = "color3", color = Color3.new(0.301960, 0.403921, 1) }, "blue")

	return world, {
		team1 = team1,
		team2 = team2,
	}
end

return {
	all_entities = all_entities,
	blank_map = blank_map,
}
