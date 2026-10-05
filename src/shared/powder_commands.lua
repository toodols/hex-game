local ReplicatedStorage = game:GetService "ReplicatedStorage"

local entity_mod = require(ReplicatedStorage.Shared.entity)
local util = require(ReplicatedStorage.Shared.util)
local types = require(ReplicatedStorage.Shared.types)
local coords_mod = require(ReplicatedStorage.Shared.coords)
local cells_mod = require(ReplicatedStorage.Shared.cells)
local world_mod = require(ReplicatedStorage.Shared.world)
local unlockable_mod = require(ReplicatedStorage.Shared.unlockable)
local deposit_types = require(ReplicatedStorage.Shared.deposit).deposit_types
local pathfinding = require(ReplicatedStorage.Shared.world.pathfinding)
local team_mod = require(ReplicatedStorage.Shared.team)

type World = types.World
type CubicCoordinate = types.CubicCoordinate

function current_world(c: any): World
	local world = _G.world
	if world == nil then
		c.fail "the game hasn't started"
	end
	return world
end

function is_cell(value: any): boolean
	return typeof(value) == "table" and value.entities ~= nil and value.coordinate ~= nil
end

function parse_coord(text: string): CubicCoordinate?
	local parts = text:split ","
	local numbers = {}
	for _, part in parts do
		local number = tonumber(part)
		if number == nil then
			return nil
		end
		table.insert(numbers, number)
	end
	if #numbers == 2 then
		return coords_mod.sanitize_coord { numbers[1], numbers[2], -numbers[1] - numbers[2] }
	elseif #numbers == 3 then
		return coords_mod.sanitize_coord(numbers)
	end
	return nil
end

function coord_from_value(value: any): CubicCoordinate?
	if is_cell(value) then
		return coords_mod.sanitize_coord(value.coordinate)
	end
	return coords_mod.sanitize_coord(value)
end

function coords_from_value(value: any): { CubicCoordinate }?
	local single = coord_from_value(value)
	if single ~= nil then
		return { single }
	end
	if typeof(value) ~= "table" then
		return nil
	end
	local result = {}
	for _, item in value do
		local coord = coord_from_value(item)
		if coord == nil then
			return nil
		end
		table.insert(result, coord)
	end
	return result
end

function selection_of(c: any, world: any): any
	local selection = if world.ui ~= nil
		then util.table_find_pred(world.ui.selection_mode_stack, function(selection_mode)
			return selection_mode.type == "select_cells"
		end)
		else nil
	if selection == nil then
		c.fail "no cells are being selected"
	end
	return selection
end

function selected_coords(c: any, world: any): { CubicCoordinate }
	return coords_mod.from_set(selection_of(c, world).selected)
end

function team_id_of_subject(c: any, world: World): number
	local team = team_mod.team_of(world, c.subject.player)
	if team == nil then
		c.fail "you aren't on a team"
	end
	return team.id
end

function setup(powder: any)
	powder.capability("gamemaster", "Changing the state of a match: timers, teams, entities and cells.")
	powder.capability("game.admin", "Saves, player data and unlockables.")
	powder.role {
		name = "gamemaster",
		description = "Runs a match: timers, teams, entities and cells.",
		capabilities = { "gamemaster" },
	}
	powder.role {
		name = "game_admin",
		description = "Gamemaster, plus saves, player data and unlockables.",
		capabilities = { "game.admin" },
		inherits = { "gamemaster" },
	}

	powder.type {
		name = "coord",
		description = "A hex coordinate, written x,y or x,y,z.",
		fromText = function(text: string)
			local coord = parse_coord(text)
			if coord == nil then
				return false, `'{text}' isn't a coordinate (x,y or x,y,z with x+y+z = 0)`
			end
			return true, coord
		end,
		fromValue = function(value: any)
			local coord = coord_from_value(value)
			if coord == nil then
				local coords = coords_from_value(value)
				if coords ~= nil and #coords > 0 then
					return true, coords[1]
				end
				return false, "expected a coordinate or a cell"
			end
			return true, coord
		end,
	}
	powder.type {
		name = "coords",
		description = "Hex coordinates, written x,y or x,y,z and separated by /, e.g. 1,-1/2,-2.",
		fromText = function(text: string)
			local result = {}
			for _, piece in text:split "/" do
				local coord = parse_coord(piece)
				if coord == nil then
					return false, `'{piece}' isn't a coordinate (x,y or x,y,z with x+y+z = 0)`
				end
				table.insert(result, coord)
			end
			return true, result
		end,
		fromValue = function(value: any)
			local coords = coords_from_value(value)
			if coords == nil then
				return false, "expected coordinates or cells"
			end
			return true, coords
		end,
	}
	powder.type {
		name = "team",
		description = "A team, by its number.",
		fromText = function(text: string)
			local id = tonumber(text)
			if id == nil then
				return false, `'{text}' isn't a team number`
			end
			local world = _G.world
			if world ~= nil and world.teams[id] == nil then
				return false, `there is no team {id}`
			end
			return true, id
		end,
		fromValue = function(value: any)
			local id = tonumber(value)
			if id == nil then
				return false, "expected a team number"
			end
			local world = _G.world
			if world ~= nil and world.teams[id] == nil then
				return false, `there is no team {id}`
			end
			return true, id
		end,
		complete = function()
			local world = _G.world
			local candidates = {}
			if world == nil then
				return candidates
			end
			for id, team in world.teams do
				table.insert(candidates, { insert = tostring(id), display = `{id} ({team.name})` })
			end
			return candidates
		end,
	}
	powder.enum("entity_type", "A kind of entity.", function()
		local keys = util.table_keys(entity_mod.registry)
		table.sort(keys)
		return keys
	end)
	powder.enum("cell_type", "A kind of cell.", function()
		local keys = util.table_keys(cells_mod.cell_names)
		table.sort(keys)
		return keys
	end)
	powder.enum("visibility", "How much of the world a team sees.", { "normal", "perfect", "fogless" })
	powder.enum("unlockable", "Something a player can unlock.", function()
		return unlockable_mod.get_unlockables()
	end)
	powder.enum("deposit_type", "A kind of deposit.", deposit_types)

	powder.namespace("select", "The cells you have selected.")
	powder.namespace("path", "Paths between cells, as your team can walk them.")
	powder.namespace("data", "Player data and the systems you can see.")
	powder.namespace("debug", "Dumping the world to the output.")

	powder.command {
		name = "coord",
		description = "A coordinate from x and y.",
		capabilities = {},
		location = "anywhere",
		params = {
			{ name = "x", type = "number", description = "The x coordinate." },
			{ name = "y", type = "number", description = "The y coordinate." },
		},
		returns = "coord",
		run = function(c: any, x: number, y: number)
			local coord = coords_mod.sanitize_coord { x, y, -x - y }
			if coord == nil then
				c.fail "x and y must be whole numbers"
			end
			return coord
		end,
	}

	powder.command {
		name = "data.show",
		description = "Your player data, as your client has it.",
		aliases = { "player_data" },
		capabilities = {},
		location = "client",
		params = {},
		returns = "table",
		run = function(c: any)
			local world = current_world(c)
			return world.player_data[tostring(c.subject.userId)] or {}
		end,
	}

	powder.command {
		name = "data.systems",
		description = "The systems your client can see.",
		aliases = { "systems" },
		capabilities = {},
		location = "client",
		params = {},
		returns = "table",
		run = function(c: any)
			return current_world(c).systems
		end,
	}

	powder.command {
		name = "select.get",
		description = "The coordinates of the cells you have selected.",
		aliases = { "selected" },
		capabilities = {},
		location = "client",
		selfOnly = true,
		params = {},
		returns = "coords",
		run = function(c: any)
			return selected_coords(c, current_world(c))
		end,
	}

	powder.command {
		name = "select.set",
		description = "Selects these cells.",
		aliases = { "set_selected" },
		capabilities = {},
		location = "client",
		selfOnly = true,
		params = { { name = "coords", type = "coords", description = "The cells to select." } },
		run = function(c: any, coords: { CubicCoordinate })
			local world = current_world(c)
			local selection = selection_of(c, world)
			selection.selected = {}
			for _, coord in coords do
				selection.selected[coords_mod.encode_coord(coord)] = true
			end
			world.ui.update()
			return nil
		end,
	}

	powder.command {
		name = "select.entities",
		description = "The entities your client can see on the selected cells, or on the cells given.",
		aliases = { "selected_entities" },
		capabilities = {},
		location = "client",
		selfOnly = true,
		params = {
			{ name = "coords", type = "coords", description = "The cells to look in.", optional = true },
		},
		returns = "table",
		run = function(c: any, coords: { CubicCoordinate }?)
			local world = current_world(c)
			local found = {}
			for _, coord in world_mod.coords_filter(world, coords or selected_coords(c, world)) do
				local cell = world:get_cell(coord)
				for entity_id in cell.entities do
					found[entity_id] = world.entities[entity_id]
				end
			end
			return util.table_values(found)
		end,
	}

	powder.command {
		name = "select.cells",
		description = "The cells you have selected, as your client sees them.",
		aliases = { "selected_cells" },
		capabilities = {},
		location = "client",
		selfOnly = true,
		params = {},
		returns = "table",
		run = function(c: any)
			local world = current_world(c)
			local cells = {}
			for _, coord in world_mod.coords_filter(world, selected_coords(c, world)) do
				table.insert(cells, world:get_cell(coord))
			end
			return cells
		end,
	}

	powder.command {
		name = "path.astar",
		description = "The shortest path between two cells.",
		aliases = { "astar" },
		capabilities = {},
		location = "client",
		params = {
			{ name = "start", type = "coord", description = "Where it starts." },
			{ name = "finish", type = "coord", description = "Where it ends." },
		},
		returns = "coords",
		run = function(c: any, start: CubicCoordinate, finish: CubicCoordinate)
			local world = current_world(c)
			local path = pathfinding.astar(world, start, finish, team_id_of_subject(c, world))
			if path == nil then
				c.fail "there is no path"
			end
			return path
		end,
	}

	powder.command {
		name = "path.bfs",
		description = "Every cell reachable from a cell within a distance.",
		aliases = { "bfs" },
		capabilities = {},
		location = "client",
		params = {
			{ name = "start", type = "coord", description = "Where it starts." },
			{ name = "distance", type = "number", description = "How far to search." },
		},
		returns = "coords",
		run = function(c: any, start: CubicCoordinate, distance: number)
			local world = current_world(c)
			return pathfinding.bfs(world, start, distance, team_id_of_subject(c, world))
		end,
	}

	powder.command {
		name = "debug.world",
		description = "Prints your client's world to the output.",
		aliases = { "debug_world_client" },
		capabilities = { "debug" },
		location = "client",
		params = {},
		run = function(c: any)
			print(current_world(c))
			c.info "Printed the world to the output."
			return nil
		end,
	}

	powder.command {
		name = "debug.fetch_world",
		description = "Fetches your view of the world from the server and prints it to the output.",
		aliases = { "debug_fetch_world" },
		capabilities = { "debug" },
		location = "client",
		params = {},
		run = function(c: any)
			local serializing = require(ReplicatedStorage.Shared.serializing)
			local get_world_data_remote = ReplicatedStorage:FindFirstChild "GetWorldDataRemote" :: RemoteFunction
			local world_data = get_world_data_remote:InvokeServer()
			print(serializing.deserialize_partial_world(world_data))
			c.info "Printed the fetched world to the output."
			return nil
		end,
	}
end

return {
	name = "hex",
	setup = setup,
}
