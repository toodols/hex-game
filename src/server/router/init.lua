local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local server_util = require(script.Parent.util)
local util = require(ReplicatedStorage.Shared.util)
local shared_entity_mod = require(ReplicatedStorage.Shared.entity)
local server_entity_mod = require(script.Parent.entity)
local entity_mod = require(script.Parent.entity)
local updates_mod = require(script.Parent.updates)
local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)
local action_phase_mod = require(script.Parent.action_phase)
local effective_visibility = require(ReplicatedStorage.Shared.effective_visibility).effective_visibility
local turn_scheduler = require(ServerScriptService.Server.turn_scheduler)

type HexGrid = types.HexGrid
type Decision = types.Decision
type TeamData = types.TeamData

function on_decision(grid: HexGrid, plr: Player, data: { Decision })
	server_util.catch(function()
		local player_team = grid:get_player_team(plr)
		if not player_team then
			return
		end
		if typeof(data) ~= "table" then
			error "Expected data to be a table"
		end

		local dirty_entities = {}

		for _, entry in data do
			if typeof(entry) ~= "table" then
				error "Expected entry to be a table"
			end
			if entry.type == "construct" then
				local cell = grid:get_cell(entry.coordinate)
				if not cell then
					return
				end

				if
					util.table_any(
						util.table_map(cell.entities, function(id)
							return grid.entities[id]
						end),
						function(entity)
							if entity.owner == player_team.id then
								return shared_entity_mod.registry[entity.type].layer
									== shared_entity_mod.registry[entry.entity_type].layer
							end
						end
					)
				then
					continue
				end

				-- or has the presence of an enemy
				local has_enemy_presence = false
				if cell.owner ~= player_team.id then
					for team_id, presence in cell.server_data.presence do
						if team_id ~= player_team.id and presence then
							has_enemy_presence = true
							break
						end
					end
					if has_enemy_presence then
						continue
					end
				end

				if not effective_visibility(cell.server_data.visibility[player_team.id]) then
					continue
				end

				local server_behavior = server_entity_mod.registry[entry.entity_type]
				if #server_behavior.built_on > 0 then
					if not table.find(server_behavior.built_on, cell.type) then
						return
					end
				end
				updates_mod.push_buffer(grid)
				local entity = entity_mod.new_entity(
					{
						type = entry.entity_type,
						owner = player_team.id,
						rotation = entry.rotation,
						primary_coordinate = entry.coordinate,
						status = "blueprint",
					},
					grid,
					{
						dirty_entities = dirty_entities,
					} :: any
				)
				updates_mod.pop_buffer(grid)
				dirty_entities[entity.id] = true
			elseif entry.type == "ability" then
				local entity = grid.entities[entry.entity_id]
				if not entity or entity.owner ~= player_team.id or entity.status ~= "complete" then
					-- error_type.mistake
					continue
				end
				local shared_behavior = shared_entity_mod.registry[entity.type]
				local ability = shared_behavior.abilities[entry.ability_type]
				if not ability then
					continue
				end

				local in_range = hex_grid_mod.coords_dist(entity.primary_coordinate, entry.coordinate) <= ability.range
					and hex_grid_mod.line_of_sight(grid, entity.primary_coordinate, entry.coordinate, player_team.id)
				if not in_range then
					continue
				end
				util.table_extract(entity.queued_decisions, function(action)
					return action.type == "ability"
				end)
				table.insert(entity.queued_decisions, entry)
				dirty_entities[entity.id] = true
			elseif entry.type == "rotate_entity" then
				local entity = grid.entities[entry.entity_id]
				if not entity or entity.owner ~= player_team.id then
					-- error_type.mistake
					continue
				end
				entity.rotation = entry.rotation
				dirty_entities[entity.id] = true
			elseif entry.type == "cancel_decision" then
				local entity = grid.entities[entry.entity_id]
				if not entity or entity.owner ~= player_team.id then
					-- error_type.mistake
					continue
				end
				util.table_extract(entity.queued_decisions, function(action)
					return action.type == entry.decision_type
				end)
				dirty_entities[entity.id] = true
			elseif entry.type == "add_research" then
				local entity = grid.entities[entry.entity_id]
				if
					not entity
					or entity.owner ~= player_team.id
					or entity.status ~= "complete"
					or entity.type ~= "laboratory"
					or not entity.researches.states[entry.research_id]
				then
					-- error_type.mistake
					continue
				end
				-- check that this research is not already in queue
				if
					util.table_find_pred(entity.researches.queue, function(research)
						return research == entry.research_id
					end)
				then
					-- error_type.dismiss
					continue
				end

				local research_state = entity.researches.states[entry.research_id]
				if research_state.status ~= "incomplete" or not research_state.precondition(grid, entity) then
					continue
				end

				research_state.status = "researching"
				table.insert(entity.researches.queue, entry.research_id)
				dirty_entities[entity.id] = true
			elseif entry.type == "remove_research" then
				local entity = grid.entities[entry.entity_id]

				if
					not entity
					or entity.owner ~= player_team.id
					or entity.status ~= "complete"
					or entity.type ~= "laboratory"
					or not entity.researches.states[entry.research_id]
				then
					-- error_type.mistake
					continue
				end

				local idx = table.find(entity.researches.queue, entry.research_id)
				-- remove all researches at and after idx
				for i = idx, #entity.researches.queue do
					entity.researches.states[entity.researches.queue[i]].status = "incomplete"
					entity.researches.queue[i] = nil
				end

				dirty_entities[entity.id] = true
			elseif entry.type == "deconstruct" then
				local entity = grid.entities[entry.entity_id]
				if not entity or entity.owner ~= player_team.id then
					-- error_type.mistake
					continue
				end
				if
					util.table_find_pred(entity.queued_decisions, function(action)
						return action.type == "deconstruct"
					end)
				then
					return 1
				end
				if entity.status == "complete" or entity.status == "scaffold" then
					table.insert(entity.queued_decisions, entry)
					dirty_entities[entity.id] = true
					updates_mod.flush_updates(grid)
				else
					server_entity_mod.remove_entity(grid, entity)
					entity_mod.trigger_neighbors(grid, grid.entities[entity.id].primary_coordinate)
				end
			elseif entry.type == "set_entity_enabled" then
				local entity = grid.entities[entry.entity_id]
				if not entity or entity.owner ~= player_team.id or entity.status ~= "complete" then
					-- error_type.mistake
					continue
				end

				entity.enabled = not not entry.enabled
				dirty_entities[entity.id] = true
			elseif entry.type == "set_recipe" then
				local entity = grid.entities[entry.entity_id]
				if not entity or entity.owner ~= player_team.id or entity.status ~= "complete" then
					-- error_type.mistake
					continue
				end
				entity.current_recipe = entry.recipe_id
				dirty_entities[entity.id] = true
			elseif entry.type == "skip" then
				if table.find(grid.skipped, plr) == nil then
					table.insert(grid.skipped, plr)
					turn_scheduler.recalculate_skips(grid)
				end
			else
				error("unknown action type: " .. entry.type)
				return 3
			end
		end

		-- reset actions for scout if it no longer has a line of sight
		-- don't know what can possibly cause this but...
		for _, entity in grid.entities do
			if entity.type == "scout" then
				local extracted = util.table_extract(entity.queued_decisions, function(action)
					if action.type == "scout" then
						if
							not hex_grid_mod.line_of_sight(
								grid,
								entity.primary_coordinate,
								action.coordinate,
								entity.owner
							)
						then
							return true
						end
					end
					return false
				end)
				if #extracted > 0 then
					warn("Scout lost line of sight", data)
					dirty_entities[entity.id] = true
				end
			end
		end

		for entity_id in dirty_entities do
			table.insert(grid.updates_buffer[#grid.updates_buffer], {
				type = "entity_update",
				entity = grid.entities[entity_id],
			})
		end
		updates_mod.flush_updates(grid)

		grid:purge_dead_entities()
		return 0
	end, plr, data)
end

return {
	on_decision = on_decision,
}
