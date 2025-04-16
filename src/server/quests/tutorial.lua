local ServerScriptService = game:GetService "ServerScriptService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local world_mod = require(ReplicatedStorage.Shared.world)
local questing = require(ServerScriptService.Server.questing)
local updates_mod = require(ServerScriptService.Server.updates)
local computed_mod = require(ServerScriptService.Server.computed)
local visibility_mod = require(ServerScriptService.Server.visibility)
local turn_scheduler = require(ServerScriptService.Server.turn_scheduler)
local util = require(ReplicatedStorage.Shared.util)
local coords = require(ReplicatedStorage.Shared.coords)

type World = types.World
type Quest = types.Quest
type CubicCoordinate = types.CubicCoordinate
type ServerQuestStageBehavior = types.ServerQuestStageBehavior
type QuestStage = types.QuestStage

local stages_behavior: { [string]: ServerQuestStageBehavior } = {
	init = {
		progression_requisite = function(self: Quest, world: World)
			for _, selections in self.tutorial_player_selection :: { [Player]: { CubicCoordinate } } do
				if #selections == 1 and coords.coords_eq(selections[1], { 0, 0, 0 }) then
					return true
				end
			end
			return false
		end,
		choice_selected = function(self: Quest, world: World, choice: string)
			if choice == "init_hint" then
				self.details.init_hint = true
			end
		end,
	},
	build_vertex_on_tile = {
		progression_requisite = function(self: Quest, world: World)
			local entities = world:query_entity { coordinate = { 0, 0, 0 } }
			if #entities == 1 then
				if entities[1].type == "vertex" then
					return true
				end
			elseif #entities > 1 then
				self.details.error_message = `Did not find exactly 1 entity in 0, 0, 0: {table.concat(
					util.table_map(entities, function(entity)
						return entity.type
					end),
					", "
				)}`
				questing.quest_change_state(self, "error", world)
				return
			end
		end,
	},
	complete_vertex_blueprint = {
		stage_start = function(self: Quest, world: World)
			assert(world.turn_schedule, "no turn schedule")
			turn_scheduler.reset_turn_time(world, world.turn_schedule)
			turn_scheduler.turn_schedule_resume(world.turn_schedule)
			turn_scheduler.report_turn_time(world)

			local unlisten
			unlisten = world.turn_schedule.turn_ran_signal.listen(function()
				unlisten()
				turn_scheduler.turn_schedule_stop(world.turn_schedule)
				turn_scheduler.report_turn_time(world)
				questing.quest_advance(self, world)
			end)
		end,
	},

	advance_until_stockpile_is_filled = {
		stage_start = function(self: Quest, world: World)
			assert(world.turn_schedule, "no turn schedule")
			if #(world:query_entity { type = "stockpile" }) == 0 then
				self.details.error_message = "stockpile not found"
				questing.quest_change_state(self, "error", world)
				return
			end
			turn_scheduler.reset_turn_time(world, world.turn_schedule)
			turn_scheduler.turn_schedule_resume(world.turn_schedule)
			turn_scheduler.report_turn_time(world)

			local unlisten
			unlisten = world.turn_schedule.turn_ran_signal.listen(function()
				local stockpile = (world:query_entity { type = "stockpile" })[1]
				if not stockpile then
					unlisten()
					self.details.error_message = "stockpile not found"
					questing.quest_change_state(self, "error", world)
					return
				end
				if #stockpile.inventory.items == 5 then
					unlisten()
					turn_scheduler.turn_schedule_stop(world.turn_schedule)
					turn_scheduler.report_turn_time(world)
					questing.quest_advance(self, world)
				end
			end)
		end,
	},
	build_scout_blueprint = {
		progression_requisite = function(self: Quest, world: World)
			return #world:query_entity { type = "scout", status = "blueprint" } == 1
		end,
	},
	complete_scout_blueprint = {
		stage_start = function(self: Quest, world: World)
			assert(world.turn_schedule, "no turn schedule")
			turn_scheduler.reset_turn_time(world, world.turn_schedule)
			turn_scheduler.turn_schedule_resume(world.turn_schedule)
			turn_scheduler.report_turn_time(world)

			local unlisten
			unlisten = world.turn_schedule.turn_ran_signal.listen(function()
				local scout = (world:query_entity { type = "scout" })[1]
				if not scout then
					unlisten()
					self.details.error_message = "scout not found"
					questing.quest_change_state(self, "error", world)
					return
				end
				if scout.status == "complete" then
					unlisten()
					turn_scheduler.turn_schedule_stop(world.turn_schedule)
					turn_scheduler.report_turn_time(world)
					questing.quest_advance(self, world)
				end
			end)
		end,
	},
	build_to_rad = {
		stage_start = function(self: Quest, world: World)
			assert(world.turn_schedule, "no turn schedule")
			world.speed_base = 6
			turn_scheduler.reset_turn_time(world, world.turn_schedule)
			turn_scheduler.turn_schedule_resume(world.turn_schedule)
			turn_scheduler.report_turn_time(world)
		end,
	},
	summon_more_cells = {
		stage_start = function(self: Quest, world: World)
			task.delay(1, function()
				for _, coord in coords.neighbors_leq({ 0, 0, 0 }, 2) do
					if not world:get_cell(coord) then
						world.cells[coords.encode_coord(coord)] = world_mod.empty_cell(coord)
					end
				end

				(world:get_cell { 1, -2, 1 } :: any).type = "rad_deposit"
				visibility_mod.compute_visibility(world)
				computed_mod.compute_presence(world)

				updates_mod.add_update(world, {
					type = "cells",
					cells = world.cells,
				})
				updates_mod.flush_updates(world)
				task.wait(1)
				questing.quest_advance(self, world)
			end)
		end,
	},
	error = {
		stage_start = function(self: Quest, world: World)
			if world.turn_schedule then
				turn_scheduler.turn_schedule_stop(world.turn_schedule)
				turn_scheduler.report_turn_time(world)
			end
		end,
	},
	restart_tutorial = {
		stage_start = function(self: Quest, world: World)
			-- todo
		end,
	},
}

local stages_data: { [string]: QuestStage } = {
	init = {
		messages = {
			"Welcome to the tutorial.",
			"First, let's learn how to build.",
			"Select (0, 0, 0) by <b>clicking</b> on the tile.{this_quest.details.init_hint?this_quest.current_stage_data.init_hint}",
		},
		init_hint = "\n<i>Hint: (0, 0, 0) is on the center of the map.</i>",
		next = "build_vertex_on_tile",
		choices = {
			{ text = "Hint", id = "init_hint" },
		},
		effects = {
			{ type = "highlight_cell", coordinate = { 0, 0, 0 } },
		},
	},
	build_vertex_on_tile = {
		messages = {
			"Information about this tile shows up on the bottom left",
			"As you can see, there is nothing on this tile yet. Let's change that.",
			"Press the build button, and select {entity.vertex}.",
		},
		effects = {
			{ type = "highlight_build_button" },
			{ type = "highlight_buildable", entity_type = "vertex" },
			{ type = "whitelist_buildable", entities = { vertex = true } },
		},
		next = "build_vertex_blueprint",
	},
	build_vertex_blueprint = {
		messages = {
			"Well done.",
			"Right now, the {entity.vertex} is blue as it is a blueprint.",
			"Blueprints require resources and time to be built.",
			"Thankfully there is a neighboring {entity.extractor} on (-1, 0, 1)",
			"Let's advance forward 1 turn",
		},
		can_advance = true,
		next = "complete_vertex_blueprint",
	},
	complete_vertex_blueprint = {
		next = "entities_are_connected",
	},
	entities_are_connected = {
		messages = {
			"This {entity.vertex} connects the {entity.extractor} to the {entity.stockpile}.",
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
			"Build a {entity.scout} blueprint anywhere.",
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
		next = "auto_turns",
	},
	auto_turns = {
		messages = {
			"Until now, turns have been manually controlled.",
			"From here on, turns will occur automatically every 6 seconds.",
		},
		can_advance = true,
		next = "build_to_rad",
	},
	build_to_rad = {
		messages = {
			"Build a {entity.extractor} on the {item.rad} deposit. Connect it to your system with the {entity.vertex}.",
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

function tutorial(world: World): Quest
	local quest = questing.new_quest {
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
		updates_mod.add_update(world, {
			type = "quest_update",
			quest = questing.quest_serialize(quest, world),
		})
		updates_mod.flush_updates(world)
	end)
	return quest
end

return {
	tutorial = tutorial,
}
