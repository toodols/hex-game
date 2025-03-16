local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)
local turn_scheduler = require(ServerScriptService.Server.turn_scheduler)
local action_phase_mod = require(ServerScriptService.Server.action_phase)
local entity_mod = require(ServerScriptService.Server.entity)

type HexGrid = types.HexGrid

-- A bunch of entities lined up
function all_entities(): HexGrid
	local grid = hex_grid_mod.new_grid_from_extents {
		{ min = -10, max = 10 },
		{ min = -10, max = 10 },
		{ min = -3, max = 3 },
	}

	local team1 = grid:new_team({}, { type = "color3", color = Color3.new(1, 0.392156, 0.392156) }, "red")
	team1.server_data.visibility = "perfect"
	local team2 = grid:new_team({}, { type = "color3", color = Color3.new(0.301960, 0.403921, 1) }, "blue")
	team2.is_player_team = false

	local start = { -9, 7, 2 }

	local function next_entity(ty: string)
		local entity = entity_mod.new_entity({
			type = ty,
			primary_coordinate = start,
			owner = team1.id,
		}, grid)
		start = {
			start[1] + 1,
			start[2] - 1,
			start[3],
		}
		return entity
	end

	grid.cells[hex_grid_mod.encode_coord(start)].type = "bar_deposit"

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

	return grid
end

-- 10x10x10 empty grid with 2 teams
function blank_map(): HexGrid
	local grid = hex_grid_mod.new_grid_from_extents {
		{ min = -10, max = 10 },
		{ min = -10, max = 10 },
		{ min = -10, max = 10 },
	}

	local team1 = grid:new_team({}, { type = "color3", color = Color3.new(1, 0.392156, 0.392156) }, "red")
	local team2 = grid:new_team({}, { type = "color3", color = Color3.new(0.301960, 0.403921, 1) }, "blue")

	return grid, {
		team1 = team1,
		team2 = team2,
	}
end

return {
	all_entities = all_entities,
	blank_map = blank_map,
}
