local ReplicatedStorage = game:GetService "ReplicatedStorage"

local entity_mod = require(ReplicatedStorage.Shared.entity)
local util = require(ReplicatedStorage.Shared.util)
local types = require(ReplicatedStorage.Shared.types)
local coords_mod = require(ReplicatedStorage.Shared.coords)
local cells_mod = require(ReplicatedStorage.Shared.cells)
local world_mod = require(ReplicatedStorage.Shared.world)

type TeamData = types.TeamData
type World = types.World

return function(extras)
	local commands = extras.commands
	local extra_types = extras.types

	commands.coord = {
		description = "Constructs a coordinate from x, y.",
		permissions = {},
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

	commands.selected = {
		description = "Gets coords of selected",
		permissions = {},
		overloads = { { returns = "coords", args = {} } },
		client_run = function(context)
			local selection = util.table_find_pred(_G.world.ui.selection_mode_stack, function(selection_mode)
				return selection_mode.type == "select_cells"
			end)
			assert(selection, "Did not find select_cells")
			return coords_mod.from_set(selection.selected)
		end,
	}

	commands.debug_world = {
		description = "Prints the world",
		permissions = { "admin" },
		overloads = { { returns = "nil", args = {} } },
		run = function(context)
			local world = _G.world
			print(world)
		end,
	}

	commands.cell_type = {
		description = "Sets the type of a cell.",
		permissions = { "admin" },
		overloads = {
			{
				returns = "nil",
				args = {
					{
						name = "type",
						type = "cell_type",
						description = "The new type.",
					},
				},
			},
			{
				returns = "nil",
				args = {

					{
						name = "type",
						type = "cell_type",
						description = "The new type.",
					},
					{
						name = "cell",
						type = "coords",
						description = "The cell to set the type for.",
					},
				},
			},
		},
		server_run = function(context)
			local world = _G.world
			local type = context.args[1]
			local coords = context.args[3] or context.runtime.run_commands_string(context.process, "selected").ok

			for _, coord in coords do
				local cell = world:get_cell(coord)
				if cell == nil then
					continue
				end
				cell.type = type
			end
		end,
	}

	commands.selected_entities = {
		description = "Gets the selected entities visible to the client.",
		permissions = { "moderator" },
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
					entities_map[_G.world.entities[entity_id]] = true
				end
			end

			return util.table_keys(entities_map)
		end,
	}

	commands.set_selected = {
		description = "Sets the selected cells.",
		permissions = {},
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
				if id_str:sub(1, #text:lower()) ~= text:lower() then
					continue
				end
				table.insert(suggestions, {
					replace_at = replace_at,
					text = id_str,
					display_text = id_str .. " (" .. team.name .. ")",
					match_start = 1,
					match_end = #text,
				})
			end
			return suggestions
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
end
