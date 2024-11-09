local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)
local questing = require(script.Parent.questing)
local effective_visibility = require(ReplicatedStorage.Shared.effective_visibility).effective_visibility
local turn_scheduler = require(script.Parent.turn_scheduler)
local server_util = require(script.Parent.util)
local server_entity_mod = require(script.Parent.entity)
local entity_mod = require(script.Parent.entity)
local updates_mod = require(script.Parent.updates)

type HexGrid = types.HexGrid
type Interaction = types.Interaction
type TeamData = types.TeamData

function on_client_interaction(grid: HexGrid, plr: Player, data: { Interaction })
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
						util.table_map(cell.entities, function(_, id)
							return grid.entities[id]
						end),
						function(entity)
							if entity.owner == player_team.id then
								return grid.entity_configurations[entity.type].layer
									== grid.entity_configurations[entry.entity_type].layer
							end
							return nil
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
				local entity = entity_mod.new_entity({
					type = entry.entity_type,
					owner = player_team.id,
					rotation = entry.rotation,
					primary_coordinate = entry.coordinate,
					status = "blueprint",
				}, grid)
				dirty_entities[entity.id] = true
			elseif entry.type == "ability" then
				local entity = grid.entities[entry.entity_id]
				if not entity or entity.owner ~= player_team.id or entity.status ~= "complete" then
					-- error_type.mistake
					continue
				end
				local shared_behavior = grid.entity_configurations[entity.type]
				local ability = shared_behavior.abilities[entry.ability_type]
				if not ability then
					continue
				end
				if entry.ability_type == "scout_attack" or entry.ability_type == "turret_attack" then
					local in_range = hex_grid_mod.coords_dist(entity.primary_coordinate, entry.coordinate)
							<= ability.range
						and hex_grid_mod.line_of_sight(
							grid,
							entity.primary_coordinate,
							entry.coordinate,
							player_team.id
						)
					if not in_range then
						continue
					end
				elseif entry.ability_type == "solution_use" then
					--ok
				end
				util.table_extract(entity.queued_decisions, function(decision)
					return decision.type == "ability" and decision.ability_type == entry.ability_type
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
				util.table_extract(entity.queued_decisions, function(decision)
					return decision.type == entry.decision_type
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

				print(entity.researches.queue, entry.research_id)
				local idx = table.find(entity.researches.queue, entry.research_id)
				if not idx then
					continue
				end
				print(idx)
				-- remove all researches at and after idx
				for i = idx, #entity.researches.queue do
					entity.researches.states[entity.researches.queue[i]].status = "incomplete"
					entity.researches.queue[i] = nil
				end
				print(entity.researches)
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
					if grid.turn_schedule then
						turn_scheduler.recalculate_skips(grid)
					end
				end
			elseif entry.type == "quest_advance" then
				local quest = grid.quests[entry.quest_id]
				if
					quest
					and quest.stages_data[quest.current_stage]
					and quest.stages_data[quest.current_stage].can_advance
				then
					questing.quest_advance(grid.quests[entry.quest_id], grid)
				end
			elseif entry.type == "tutorial_report_selection" then
				local tutorial = grid.quests.tutorial
				if tutorial then
					(tutorial.tutorial_player_selection :: any)[plr] = entry.selected
					questing.quest_update(tutorial, grid)
				end
			else
				error("unknown interaction type: " .. entry.type)
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
			updates_mod.add_update(grid, {
				type = "entity_update",
				entity = grid.entities[entity_id],
			})
		end

		for _, quest in grid.quests do
			questing.quest_update(quest, grid)
		end

		updates_mod.flush_updates(grid)

		grid:purge_dead_entities()
		return 0
	end, plr, data)
end

return {
	on_client_interaction = on_client_interaction,
}
