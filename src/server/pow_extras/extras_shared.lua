local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local entity_mod = require(ReplicatedStorage.Shared.entity)
local util = require(ReplicatedStorage.Shared.util)
local types = require(ReplicatedStorage.Shared.types)
local coords_mod = require(ReplicatedStorage.Shared.coords)
local cells_mod = require(ReplicatedStorage.Shared.cells)
local structures = require(ReplicatedStorage.Shared.structures)
local world_mod = require(ReplicatedStorage.Shared.world)
local unlockable_mod = require(ReplicatedStorage.Shared.unlockable)
local deposit_types = require(ReplicatedStorage.Shared.deposit).deposit_types
local pathfinding = require(ReplicatedStorage.Shared.world.pathfinding)
local team_mod = require(ReplicatedStorage.Shared.team)

type TeamData = types.TeamData
type World = types.World

return function(extras, modules)
	local commands = extras.commands
	local extra_types = extras.types
	local permission_types = extras.permission_types
	permission_types.admin = { "gamemaster" }
	permission_types.normal = { "automation" }
	permission_types.gamemaster = {}

	commands.coord = {
		description = "Constructs a coordinate from x, y.",
		permissions = { "automation" },
		overloads = {
			{
				returns = "coord",
				args = {
					{
						name = "x",
						type = "number",
						description = "The x coordinate.",
					},
					{
						name = "y",
						type = "number",
						description = "The y coordinate.",
					},
				},
			},
		},
		run = function(context)
			local x = context.args[1]
			local y = context.args[2]
			return { x, y, -x - y }
		end,
	}

	commands.player_data = {
		description = "Returns the executor's player data",
		permissions = { "automation" },
		overloads = { { returns = "any", args = {} } },
		client_run = function(context)
			local player = context.executor
			return _G.world.player_data[tostring(player.UserId)] or {}
		end,
	}

	commands.selected = {
		description = "Gets coords of selected",
		permissions = { "automation" },
		overloads = { { returns = "coords", args = {} } },
		client_run = function(context)
			local selection = util.table_find_pred(_G.world.ui.selection_mode_stack, function(selection_mode)
				return selection_mode.type == "select_cells"
			end)
			assert(selection, "Did not find select_cells")
			return coords_mod.from_set(selection.selected)
		end,
	}

	commands.astar = {
		description = "Finds a path between two coords",
		permissions = { "automation" },
		overloads = {
			{
				returns = "coords",
				args = {
					{
						name = "start",
						type = "coord",
						description = "The start coord",
					},
					{
						name = "end",
						type = "coord",
						description = "The end coord",
					},
				},
			},
		},
		client_run = function(context)
			local start = context.args[1]
			local finish = context.args[2]
			local world = _G.world
			local team = team_mod.team_of(world, context.executor)
			return pathfinding.astar(_G.world, start, finish, team.id)
		end,
	}

	commands.bfs = {
		description = "Lists all coordinates that are reachable from the start coord without distance",
		permissions = { "automation" },
		overloads = {
			{
				returns = "coords",
				args = {
					{
						name = "start",
						type = "coord",
						description = "The start coord",
					},
					{
						name = "distance",
						type = "number",
						description = "The distance to search",
					},
				},
			},
		},
		client_run = function(context)
			local start = context.args[1]
			local distance = context.args[2]
			local world = _G.world
			local team = team_mod.team_of(world, context.executor)
			return pathfinding.bfs(_G.world, start, distance, team.id)
		end,
	}

	commands.debug_world_client = {
		description = "Prints the world",
		permissions = { "debug" },
		overloads = { { returns = "nil", args = {} } },
		client_run = function(context)
			local world = _G.world
			print(world)
		end,
	}

	commands.debug_fetch_world = {
		description = "Prints the world",
		permissions = { "debug" },
		overloads = { { returns = "nil", args = {} } },
		client_run = function(context)
			local get_world_data_remote = ReplicatedStorage:FindFirstChild "GetWorldDataRemote" :: RemoteFunction
			local world_data = get_world_data_remote:InvokeServer()
			local world = structures.deserialize_partial_world(world_data)
			print(world)
		end,
	}

	commands.systems = {
		description = "Returns the systems visible to the client.",
		permissions = { "automation" },
		overloads = { { returns = "any", args = {} } },
		client_run = function(context)
			return _G.world.systems
		end,
	}

	commands.selected_entities = {
		description = "Gets the selected entities visible to the client.",
		permissions = { "automation" },
		overloads = {
			{ returns = "entities", args = {} },
			{
				returns = "entities",
				args = {
					{ name = "coords", type = "coords", description = "The cells to get the entities from." },
				},
			},
		},
		client_run = function(context)
			local coords
			if context.args[1] then
				coords = world_mod.coords_filter(_G.world, context.args[1])
			else
				coords = context.runtime.run_commands_string(context.process, "selected").ok
			end
			local entities_map = {}
			for _, coord in coords do
				local cell = _G.world:get_cell(coord)
				for entity_id in cell.entities do
					entities_map[entity_id] = true
				end
			end

			return util.table_map(entities_map, function(_, entity_id)
				return _G.world.entities[entity_id]
			end)
		end,
	}

	commands.selected_cells = {
		description = "Gets the selected cells visible to the client.",
		permissions = { "automation" },
		overloads = { { returns = "cells", args = {} } },
		client_run = function(context)
			local coords
			if context.args[1] then
				coords = world_mod.coords_filter(_G.world, context.args[1])
			else
				coords = context.runtime.run_commands_string(context.process, "selected").ok
			end
			local cells = {}
			for _, coord in coords do
				local cell = _G.world:get_cell(coord)
				cells[coords_mod.encode_coord(coord)] = cell
			end
			return cells
		end,
	}

	commands.set_selected = {
		description = "Sets the selected cells.",
		permissions = { "automation" },
		overloads = {
			{
				returns = "nil",
				args = {
					{
						name = "coords",
						type = "coords",
						description = "The coordinates to set.",
					},
				},
			},
		},
		client_run = function(context)
			local world = _G.world
			local coords = context.args[1]
			local selection = util.table_find_pred(world.ui.selection_mode_stack, function(selection_mode)
				return selection_mode.type == "select_cells"
			end)
			assert(selection, "Did not find select_cells")
			selection.selected = {}
			for _, coord in coords do
				local encoded_coord = coords_mod.encode_coord(coord)
				selection.selected[encoded_coord] = true
			end
			_G.world.ui.update()
		end,
	}

	extra_types.entity_type = {
		autocomplete_simple = util.table_keys(entity_mod.registry),
	}

	extra_types.team = {
		coerce_expression = function(value, context)
			if value.type == "string" then
				return { ok = tonumber(value.value) }
			end
			return { err = "cannot coerce " .. value.type .. " to team" }
		end,
		autocomplete = function(text, replace_at, process)
			local world = _G.world
			local suggestions = {}
			for id, team in world.teams do
				local id_str = tostring(id)
				table.insert(suggestions, {
					replace_at = replace_at,
					text = id_str,
					display_text = id_str .. " (" .. team.name .. ")",
				})
			end
			return modules.util.search(suggestions, text)
		end,
	}

	extra_types.cell_type = {
		autocomplete_simple = util.table_keys(cells_mod.cell_names),
	}
	extra_types.visibility = {
		autocomplete_simple = { "normal", "perfect", "fogless" },
	}

	local function is_cell(value)
		return typeof(value) == "table" and value.entities ~= nil
	end

	local function is_coord(value)
		return typeof(value) == "table"
			and typeof(value[1]) == "number"
			and typeof(value[2]) == "number"
			and typeof(value[3]) == "number"
	end

	local function is_array_of(value, type)
		if typeof(value) ~= "table" then
			return false
		end
		if #value >= 1 then
			if type(value[1]) then
				return true
			end
		end
		return false
	end

	extra_types.cell = {
		coerce_value = function(value, context)
			if is_cell(value) then
				return { ok = value }
			end
			if is_array_of(value, is_cell) then
				return { ok = value[1] }
			end
			return { err = "cannot coerce " .. typeof(value) .. " to cell" }
		end,
	}

	extra_types.cells = {
		coerce_value = function(value, context)
			if is_cell(value) then
				return { ok = { value } }
			end
			if is_array_of(value, is_cell) then
				return { ok = value }
			end
			return { err = "cannot coerce " .. typeof(value) .. " to cells" }
		end,
	}

	extra_types.coord = {
		-- can be `x,y` or `x,y,z`
		coerce_expression = function(value, context)
			if value.type == "string" then
				local coords = value.value:split ","
				if #coords == 2 then
					local x = tonumber(coords[1]) :: number
					local y = tonumber(coords[2]) :: number
					return { ok = { x, y, -x - y } }
				elseif #coords == 3 then
					return { ok = { tonumber(coords[1]), tonumber(coords[2]), tonumber(coords[3]) } }
				end
			end
			return { err = "cannot coerce " .. value.type .. " to coord" }
		end,
		coerce_value = function(value, context)
			if is_coord(value) then
				return { ok = value }
			end
			if is_array_of(value, is_coord) then
				return { ok = value[1] }
			end
			if is_cell(value) then
				return { ok = value.coordinate }
			end
			if is_array_of(value, is_cell) then
				return { ok = value[1].coordinate }
			end
			return { err = "cannot coerce " .. typeof(value) .. " to coord" }
		end,
	}

	extra_types.coords = {
		-- if it is a 3-length number array, it is a coord, and can be coerced to a {coord}
		coerce_value = function(value, context)
			if is_coord(value) then
				return { ok = { value } }
			end
			if is_array_of(value, is_coord) then
				return { ok = value }
			end
			if is_cell(value) then
				return { ok = { value.coordinate } }
			end
			if is_array_of(value, is_cell) then
				return { ok = util.table_map(value, function(cell)
					return cell.coordinate
				end) }
			end
			return { err = "cannot coerce " .. typeof(value) .. " to coords" }
		end,
	}

	extra_types.entity = {
		coerce_value = function(value, context)
			if typeof(value) == "string" then
				if _G.world.entities[value] then
					return { ok = _G.world.entities[value] }
				else
					return { err = "entity not found for " .. value }
				end
			elseif typeof(value) == "table" then
				return { ok = value }
			else
				return { err = "cannot coerce " .. typeof(value) .. " to entity" }
			end
		end,
	}

	extra_types.entity_id = {
		coerce_value = function(value, context)
			if typeof(value) == "table" and typeof(value.id) == "string" then
				return { ok = value.id }
			elseif typeof(value) == "string" then
				return { ok = value }
			else
				return { err = "cannot coerce " .. typeof(value) .. " to entity_id" }
			end
		end,
	}

	extra_types.unlockable = {
		autocomplete_simple = unlockable_mod.get_unlockables(),
	}

	extra_types.deposit_type = {
		autocomplete_simple = deposit_types,
	}
end
