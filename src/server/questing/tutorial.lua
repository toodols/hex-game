local ServerScriptService = game:GetService "ServerScriptService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local action_phase_mod = require(ServerScriptService.Server.action_phase)
local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)
local quest_methods = require(script.Parent.quest)
local updates_mod = require(ServerScriptService.Server.updates)
local computed_mod = require(ServerScriptService.Server.computed)
local turn_scheduler = require(ServerScriptService.Server.turn_scheduler)

type HexGrid = types.HexGrid
type Quest = types.Quest
type CubicCoordinate = types.CubicCoordinate
type ServerQuestStageBehavior = types.ServerQuestStageBehavior
type QuestStage = types.QuestStage

local stages_behavior: { [string]: ServerQuestStageBehavior } = {
	init = {
		progression_requisite = function(self: Quest, grid: HexGrid)
			for _, selections in self.tutorial_player_selection :: { [Player]: { CubicCoordinate } } do
				if #selections == 1 and hex_grid_mod.coords_eq(selections[1], { 0, 0, 0 }) then
					return true
				end
			end
			return false
		end,
	},
	build_wires_on_tile = {
		progression_requisite = function(self: Quest, grid: HexGrid)
			return #grid:query_entity { primary_coordinate = { 0, 0, 0 }, type = "wires" } == 1
		end,
	},
	complete_wires_blueprint = {
		stage_start = function(self: Quest, grid: HexGrid)
			assert(grid.turn_schedule, "no turn schedule")
			turn_scheduler.reset_turn_time(grid, grid.turn_schedule)
			turn_scheduler.turn_schedule_resume(grid.turn_schedule)
			turn_scheduler.report_turn_time(grid)

			local unlisten
			unlisten = grid.turn_schedule.turn_ran_signal.listen(function()
				unlisten()
				turn_scheduler.turn_schedule_stop(grid.turn_schedule)
				turn_scheduler.report_turn_time(grid)
				quest_methods.quest_advance(self, grid)
			end)
		end,
	},

	advance_until_stockpile_is_filled = {
		stage_start = function(self: Quest, grid: HexGrid)
			assert(grid.turn_schedule, "no turn schedule")
			if #(grid:query_entity { type = "stockpile" }) == 0 then
				self.details.error_message = "stockpile not found"
				quest_methods.quest_change_state(self, "error", grid)
				return
			end
			turn_scheduler.reset_turn_time(grid, grid.turn_schedule)
			turn_scheduler.turn_schedule_resume(grid.turn_schedule)
			turn_scheduler.report_turn_time(grid)

			local unlisten
			unlisten = grid.turn_schedule.turn_ran_signal.listen(function()
				local stockpile = (grid:query_entity { type = "stockpile" })[1]
				if not stockpile then
					unlisten()
					self.details.error_message = "stockpile not found"
					quest_methods.quest_change_state(self, "error", grid)
					return
				end
				if #stockpile.inventory.items == 5 then
					unlisten()
					turn_scheduler.turn_schedule_stop(grid.turn_schedule)
					turn_scheduler.report_turn_time(grid)
					quest_methods.quest_advance(self, grid)
				end
			end)
		end,
	},
	build_scout_blueprint = {
		progression_requisite = function(self: Quest, grid: HexGrid)
			return #grid:query_entity { type = "scout", status = "blueprint" } == 1
		end,
	},
	complete_scout_blueprint = {
		stage_start = function(self: Quest, grid: HexGrid)
			assert(grid.turn_schedule, "no turn schedule")
			turn_scheduler.reset_turn_time(grid, grid.turn_schedule)
			turn_scheduler.turn_schedule_resume(grid.turn_schedule)
			turn_scheduler.report_turn_time(grid)

			local unlisten
			unlisten = grid.turn_schedule.turn_ran_signal.listen(function()
				local scout = (grid:query_entity { type = "scout" })[1]
				if not scout then
					unlisten()
					self.details.error_message = "scout not found"
					quest_methods.quest_change_state(self, "error", grid)
					return
				end
				if scout.status == "complete" then
					unlisten()
					turn_scheduler.turn_schedule_stop(grid.turn_schedule)
					turn_scheduler.report_turn_time(grid)
					quest_methods.quest_advance(self, grid)
				end
			end)
		end,
	},
	summon_more_cells = {
		stage_start = function(self: Quest, grid: HexGrid)
			task.delay(1, function()
				for _, coord in hex_grid_mod.neighbors_leq({ 0, 0, 0 }, 2) do
					if not grid:get_cell(coord) then
						grid.cells[hex_grid_mod.encode_coord(coord)] = hex_grid_mod.empty_cell(coord)
					end
				end

				(grid:get_cell { 1, -2, 1 } :: any).type = "rad_deposit"
				computed_mod.compute_visibility(grid)
				computed_mod.compute_presence(grid)

				updates_mod.add_update_and_flush(grid, {
					type = "cells",
					cells = grid.cells,
				})
				wait(1)
				quest_methods.quest_advance(self, grid)
			end)
		end,
	},
	error = {
		stage_start = function(self: Quest, grid: HexGrid)
			if grid.turn_schedule then
				turn_scheduler.turn_schedule_stop(grid.turn_schedule)
				turn_scheduler.report_turn_time(grid)
			end
		end,
	},
	restart_tutorial = {
		stage_start = function(self: Quest, grid: HexGrid)
			-- todo
		end,
	},
}

local stages_data: { [string]: QuestStage } = {
	init = {
		messages = {
			"Welcome to the tutorial.",
			"First, let's learn how to build.",
			"Select (0, 0, 0) by clicking on the tile.",
		},
		next = "build_wires_on_tile",
		effects = {
			{ type = "highlight_cell", coordinate = { 0, 0, 0 } },
		},
	},
	build_wires_on_tile = {
		messages = {
			"As you can see, there is nothing on this tile yet. Let's change that.",
			"Press the build button, and select {entity.wires}.",
		},
		effects = {
			{ type = "highlight_build_button" },
			{ type = "highlight_buildable", entity_type = "wires" },
		},
		next = "build_wires_blueprint",
	},
	build_wires_blueprint = {
		messages = {
			"Well done.",
			"Right now, the {entity.wires} is blue as it is a blueprint.",
			"Blueprints require resources and time to be built.",
			"Thankfully there is a neighboring {entity.extractor} on (-1, 0, 1)",
			"Let's advance forward 1 turn",
		},
		can_advance = true,
		next = "complete_wires_blueprint",
	},
	complete_wires_blueprint = {
		next = "entities_are_connected",
	},
	entities_are_connected = {
		messages = {
			"This {entity.wires} connects the {entity.extractor} to the {entity.stockpile}.",
			"Every turn this {entity.extractor} will generate one item.",
			"Let's advance a few turns so the stockpile fills up.",
		},
		can_advance = true,
		next = "advance_until_stockpile_is_filled",
	},
	advance_until_stockpile_is_filled = {
		next = "build_scout_blueprint",
	},
	build_scout_blueprint = {
		messages = {
			"This gray resource is called {item.bar}.",
			"It can be used to build more buildings.",
			"One of these buildings is a {entity.scout}.",
			"Build a {entity.scout} blueprint anywhere. Hint: You don't need to build {entity.wires} beforehand on an empty tile.",
		},
		next = "complete_scout_blueprint",
	},
	complete_scout_blueprint = {
		next = "scout_is_complete",
	},
	scout_is_complete = {
		messages = {
			"The {entity.scout} is complete. This building can attack enemies that get too close.",
			"But it needs ammunition. For that we need to acquire {item.rad}",
		},
		can_advance = true,
		next = "summon_more_cells",
	},
	summon_more_cells = {
		next = "build_to_rad",
	},
	build_to_rad = {
		messages = {
			"Build an {entity.extractor} on the {item.rad} deposit",
		},
	},
	error = {
		messages = {
			"<font color='#ff0000'>Error!!</font> You played my tutorial incorrectly! Reason: {quest.tutorial.details.error_message}.",
		},
		next = "restart_tutorial",
		-- can_advance = true,
	},
	restart_tutorial = {
		next = "init",
	},
}

function tutorial(grid: HexGrid): Quest
	local quest = quest_methods.new_quest {
		id = "tutorial",
		title = "Tutorial",
		stages_data = stages_data,
		stages_behavior = stages_behavior,
		details = {
			error_message = "<unknown>",
		},
	}
	quest.tutorial_player_selection = {}
	quest.quest_update_signal.listen(function()
		updates_mod.add_update(grid, {
			type = "quest_update",
			quest_id = quest.id,
			current_stage = quest.current_stage,
			stages_data = quest.stages_data,
			details = quest.details,
			title = quest.title,
		})
		updates_mod.flush_updates(grid)
	end)
	return quest
end

return {
	tutorial = tutorial,
}
