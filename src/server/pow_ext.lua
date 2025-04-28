local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local entity_mod = require(ReplicatedStorage.Shared.entity)
local util = require(ReplicatedStorage.Shared.util)
local types = require(ReplicatedStorage.Shared.types)
local coords_mod = require(ReplicatedStorage.Shared.coords)

type TeamData = types.TeamData
type World = types.World

return function()
	local entity_prop_meta = {}
	local extra_commands = {}

	extra_commands.set_visibility = {
		description = "Sets the visibility of a team.",
		permissions = { "admin" },
		overloads = {
			{
				returns = "nil",
				args = {
					{
						name = "team",
						type = "team",
						description = "The team to set the visibility for.",
					},
					{
						name = "visibility",
						type = "visibility",
						description = "The new visibility.",
					},
				},
			},
		},
		server_run = function(context)
			local world = _G.world
			local team_id = context.args[1]
			local visibility = context.args[2]
			local team = world.teams[team_id]
			team.server_data.visibility = visibility
		end,
	}

	extra_commands.coord = {
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

	extra_commands.selected_cells = {
		description = "Gets the selected cells.",
		permissions = {},
		overloads = { { returns = "coords", args = {} } },
		run = function(context)
			local selection = util.table_find_pred(_G.world.ui.selection_mode_stack, function(selection_mode)
				return selection_mode.type == "select_cells"
			end)
			assert(selection, "Did not find select_cells")
			local cells = selection.selected
			local coords = {}
			for cell_instance in cells do
				local coord = _G.world.instance_cell_map[cell_instance]
				assert(coord, "cell_instance not in instance_cell_map")
				table.insert(coords, coords_mod.decode_coord(coord))
			end
			return coords
		end,
	}

	extra_commands.selected_cell = {
		description = "Gets one selected_cell.",
		permissions = {},
		overloads = { { returns = "coord", args = {} } },
		run = function(context)
			local selection = util.table_find_pred(_G.world.ui.selection_mode_stack, function(selection_mode)
				return selection_mode.type == "select_cells"
			end)
			assert(selection, "Did not find select_cells")
			local cells = selection.selected
			for cell_instance in cells do
				local coord = _G.world.instance_cell_map[cell_instance]
				assert(coord, "cell_instance not in instance_cell_map")
				return coords_mod.decode_coord(coord)
			end
			return nil
		end,
	}

	extra_commands.selected_entities_server = {
		description = "Gets all entities at the given coordinates.",
		permissions = { "admin" },
		overloads = {
			{
				returns = "entities",
				args = {},
			},
			{
				returns = "entities",
				args = {
					{
						name = "coords",
						type = "coords",
						description = "The coordinates to get the entities from.",
					},
				},
			},
		},
		server_run = function(context)
			local coords
			if context.args[1] then
				coords = util.table_map(context.args[1], coords.encode_coord)
			else
				coords = {}
				local selection = util.table_find_pred(_G.world.ui.selection_mode_stack, function(selection_mode)
					return selection_mode.type == "select_cells"
				end)
				if selection == nil then
					return {}
				end
				for cell_instance in selection.selected do
					local coord = _G.world.instance_cell_map[cell_instance]
					assert(coord, "cell_instance not in instance_cell_map")
					table.insert(coords, coord)
				end
			end
			local entities_map = {}
			for _, encoded_coord in coords do
				local cell = _G.world.cells[encoded_coord]
				if cell == nil then
					continue
				end
				for entity_id in cell.entities do
					entities_map[_G.world.entities[entity_id]] = true
				end
			end

			return util.table_keys(entities_map)
		end,
	}

	extra_commands.selected_entities = {
		description = "Gets the selected entities visible to the client.",
		permissions = {},
		overloads = {
			{ returns = "entities", args = {} },
			{
				returns = "entities",
				args = {
					{ name = "cells", type = "coords", description = "The cells to get the entities from." },
				},
			},
		},
		run = function(context)
			local coords
			if context.args[1] then
				coords = util.table_map(context.args[1], coords.encode_coord)
			else
				coords = {}
				local selection = util.table_find_pred(_G.world.ui.selection_mode_stack, function(selection_mode)
					return selection_mode.type == "select_cells"
				end)
				if selection == nil then
					return {}
				end
				for cell_instance in selection.selected do
					local coord = _G.world.instance_cell_map[cell_instance]
					assert(coord, "cell_instance not in instance_cell_map")
					table.insert(coords, coord)
				end
			end
			local entities_map = {}
			for _, encoded_coord in coords do
				local cell = _G.world.cells[encoded_coord]
				if cell == nil then
					continue
				end
				for entity_id in cell.entities do
					entities_map[_G.world.entities[entity_id]] = true
				end
			end

			return util.table_keys(entities_map)
		end,
	}

	extra_commands.pause_timer = {
		description = "Pauses the timer.",
		permissions = { "admin" },
		overloads = {
			{ returns = "nil", args = {} },
		},
		server_run = function(context)
			local turn_scheduler = require(ServerScriptService.Server.turn_scheduler)
			local world = _G.world
			turn_scheduler.turn_schedule_stop(world.turn_schedule)
			turn_scheduler.report_turn_time(world)
		end,
	}

	extra_commands.resume_timer = {
		description = "Resumes the timer.",
		permissions = { "admin" },
		overloads = {
			{ returns = "nil", args = {} },
		},
		server_run = function(context)
			local turn_scheduler = require(ServerScriptService.Server.turn_scheduler)
			local world = _G.world
			turn_scheduler.turn_schedule_resume(world.turn_schedule)
			turn_scheduler.report_turn_time(world)
		end,
	}

	extra_commands.skip_timer = {
		description = "Skips the timer.",
		permissions = { "admin" },
		overloads = {
			{ returns = "nil", args = {} },
		},
		server_run = function(context)
			local turn_scheduler = require(ServerScriptService.Server.turn_scheduler)
			local world = _G.world
			turn_scheduler.turn_schedule_skip(world.turn_schedule)
		end,
	}

	extra_commands.query_entity = {
		description = "Queries an entity by type",
		permissions = {},
		overloads = {
			{
				returns = "entities",
				args = {
					{
						name = "entity_prop",
						type = "entity_prop",
						description = "The entity property to query.",
						rest = true,
					},
				},
			},
		},
		run = function(context)
			local world = _G.world
			local props = { query_global = true }
			for _, prop in context.args do
				if getmetatable(prop) == entity_prop_meta then
					props[prop.property] = prop.value
				end
			end
			return world:query_entity(props)
		end,
	}

	extra_commands.query_entity_server = {
		description = "Queries an entity by type, runs on the server.",
		permissions = { "admin" },
		overloads = {
			{
				returns = "entities",
				args = {
					{
						name = "entity_prop",
						type = "entity_prop",
						description = "The entity property to query.",
						rest = true,
					},
				},
			},
		},
		server_run = function(context)
			local world = _G.world
			local props = {}
			for _, prop in context.args do
				if getmetatable(prop) == entity_prop_meta then
					props[prop.property] = prop.value
				end
			end
			return world:query_entity(props)
		end,
	}

	extra_commands.set_selected = {
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
		run = function(context)
			local world = _G.world
			local coords = context.args[1]
			local selection = util.table_find_pred(world.ui.selection_mode_stack, function(selection_mode)
				return selection_mode.type == "select_cells"
			end)
			assert(selection, "Did not find select_cells")
			selection.selected = {}
			for _, coord in coords do
				local cell_instance = world.cell_instance_map[coords_mod.encode_coord(coord)]
				assert(cell_instance, "cell_instance not in cell_instance_map")
				selection.selected[cell_instance] = true
			end
			_G.world.ui.update()
		end,
	}

	extra_commands.entity_prop_type = {
		alias = { "ep_type" },
		description = "Creates a queryable property for an entity type.",
		permissions = {},
		overloads = {
			{
				returns = "entity_prop",
				args = {
					{
						name = "entity",
						type = "entity_type",
						description = "The type of entity to query.",
					},
				},
			},
		},
		run = function(context)
			return setmetatable({
				property = "type",
				value = context.args[1],
			}, entity_prop_meta)
		end,
	}

	extra_commands.entity_prop_owner = {
		alias = { "ep_owner" },
		description = "Creates a queryable property for an entity type.",
		permissions = {},
		overloads = {
			{
				returns = "entity_prop",
				args = {
					{
						name = "owner",
						type = "team",
						description = "The team that owns the entity.",
					},
				},
			},
		},
		run = function(context)
			return setmetatable({
				property = "owner",
				value = context.args[1],
			}, entity_prop_meta)
		end,
	}

	extra_commands.spawn_entity = {
		description = "spawn_entity",
		permissions = {},
		overloads = {
			{
				returns = "nil",
				args = {

					{
						name = "entity_type",
						type = "entity_type",
						description = "The type of entity to spawn.",
					},
					{
						name = "owner",
						type = "team",
						description = "The team that owns the entity.",
					},
					{
						name = "coord",
						type = "coord",
						description = "The coordinate of the entity.",
					},
				},
			},
		},
		server_run = function(context)
			local world = _G.world
			local server_entity_mod = require(ServerScriptService.Server.entity)
			local entity_type = context.args[1]
			local team = context.args[2]
			local coord = context.args[3]
			server_entity_mod.new_entity({
				type = entity_type,
				primary_coordinate = coord,
				owner = team,
			}, world)
		end,
	}

	local extra_types = {}
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

	extra_types.visibility = {
		autocomplete_simple = { "normal", "perfect", "fogless" },
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
	}

	extra_types.coords = {
		-- if it is a 3-length number array, it is a coord, and can be coerced to a {coord}
		coerce_value = function(value, context)
			if typeof(value) == "table" then
				if
					#value == 3
					and typeof(value[1]) == "number"
					and typeof(value[2]) == "number"
					and typeof(value[3]) == "number"
				then
					return { ok = { value } }
				else
					return { ok = value }
				end
			else
				return { err = "cannot coerce " .. typeof(value) .. " to coords" }
			end
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

	extra_types.entity_prop = {
		coerce_value = function(value, context)
			if typeof(value) == "table" and getmetatable(value) == entity_prop_meta then
				return { ok = value }
			else
				return { err = "cannot coerce " .. typeof(value) .. " to entity_prop" }
			end
		end,
	}

	return {
		types = extra_types,
		commands = extra_commands,
	}
end
