local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local entity_mod = require(ReplicatedStorage.Shared.entity)
local util = require(ReplicatedStorage.Shared.util)
local types = require(ReplicatedStorage.Shared.types)
local coords_mod = require(ReplicatedStorage.Shared.coords)

type TeamData = types.TeamData

return function()
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
						name = "x",
						type = "number",
						description = "The x coordinate of the entity.",
					},
					{
						name = "y",
						type = "number",
						description = "The y coordinate of the entity.",
					},
				},
			},
		},
		server_run = function(context)
			local world = _G.world
			local server_entity_mod = require(ServerScriptService.Server.entity)
			local entity_type = context.args[1]
			local x = context.args[2]
			local y = context.args[3]
			local team = (util.table_find_pred(world.teams, function(candidate)
				return candidate.is_player_team
			end) :: TeamData).id
			server_entity_mod.new_entity({
				type = entity_type,
				primary_coordinate = { x, y, -x - y },
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
	extra_types.coord = {}
	extra_types.coords = {}

	return {
		types = extra_types,
		commands = extra_commands,
	}
end
