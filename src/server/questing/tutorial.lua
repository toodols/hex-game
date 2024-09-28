local ServerScriptService = game:GetService "ServerScriptService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local action_phase_mod = require(ServerScriptService.Server.action_phase)
local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)
local quest_methods = require(script.Parent.quest)
local updates_mod = require(ServerScriptService.Server.updates)

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
	build_wires_blueprint = {
		stage_start = function(self: Quest, grid: HexGrid)
			task.delay(1, function()
				action_phase_mod.run_action_phase(grid)
				wait(1)
				quest_methods.quest_advance(self, grid)
			end)
		end,
	},
	advance_until_stockpile_is_filled = {
		stage_start = function(self: Quest, grid: HexGrid)
			task.delay(1, function()
				while true do
					local stockpile = (grid:query_entity { type = "stockpile" })[1]
					if not stockpile then
						quest_methods.quest_change_state(self, "error", grid)
					end

					action_phase_mod.run_action_phase(grid)
					wait(1)
					if #stockpile.inventory.items == 5 then
						break
					end
				end
				quest_methods.quest_advance(self, grid)
			end)
		end,
	},
}

local stages_data: { [string]: QuestStage } = {
	init = {
		messages = {
			"Welcome to the tutorial.",
			"Select (0, 0, 0) by clicking on the tile.",
		},
		next = "build_wires_on_tile",
		effects = {
			{ type = "highlight_cell", coordinate = { 0, 0, 0 } },
		},
	},
	build_wires_on_tile = {
		messages = {
			"Press the build button, and select {entity.wires}.",
		},
		effects = {
			{ type = "highlight_build_button" },
			{ type = "highlight_buildable", entity_type = "wires" },
		},
		next = "complete_wires_blueprint",
	},
	complete_wires_blueprint = {
		messages = {
			"Right now, the {entity.wires} is a blueprint. Let's advance forward 1 turn",
		},
		can_advance = true,
		next = "build_wires_blueprint",
	},
	build_wires_blueprint = {
		next = "entities_are_connected",
	},
	entities_are_connected = {
		messages = {
			"The buildings are now connected. Every turn this extractor will generate one item.",
			"Let's advance a few turns so the stockpile fills up.",
		},
		can_advance = true,
		next = "advance_until_stockpile_is_filled",
	},
	advance_until_stockpile_is_filled = {
		next = "resource_is_bar",
	},
	resource_is_bar = {
		messages = {
			"This gray resource is called {item.bar}.",
			"But it isn't the only resource. Let's obtain {item.rad}",
		},
	},
	error = {
		messages = {
			"Something went wrong and the tutorial can no longer function.",
		},
	},
}

function tutorial(grid: HexGrid): Quest
	local quest = quest_methods.new_quest {
		id = "tutorial",
		title = "Tutorial",
		stages_data = stages_data,
		stages_behavior = stages_behavior,
	}
	quest.tutorial_player_selection = {}
	quest.quest_update_signal.listen(function()
		updates_mod.add_update(grid, {
			type = "quest_update",
			quest_id = quest.id,
			current_stage = quest.current_stage,
			stages_data = quest.stages_data,
			details = quest.details,
		})
		updates_mod.flush_updates(grid)
	end)
	return quest
end

return {
	tutorial = tutorial,
}
