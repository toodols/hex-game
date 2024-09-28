local ServerScriptService = game:GetService "ServerScriptService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local action_phase_mod = require(ServerScriptService.Server.action_phase)
local quest_from_stages = require(script.Parent.quest).quest_from_stages

type HexGrid = types.HexGrid
type Quest = types.Quest

local tutorial_stages_server = {
	build_wires_on_tile = {
		progression_requisite = function(self: Quest, grid: HexGrid)
			return #grid:query_entity { primary_coordinate = { 0, 0, 0 }, type = "wires" } == 0
		end,
	},
	complete_wires_blueprint = {
		stage_start = function(self: Quest, grid: HexGrid)
			action_phase_mod.run_action_phase(grid)
		end,
	},
}

local tutorial_stages = {
	init = {
		messages = {
			"Welcome to the tutorial.",
			"Before you are two buildings, a {entity.extractor} and a {entity.stockpile}.",
			"The {entity.extractor} creates items while the {entity.stockpile} stores items",
			"You can connect them with a {entity.wires}.",
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
		next = "resource_is_bar",
	},
	resource_is_bar = {
		messages = {
			"This gray resource is called {item.bar}.",
			"But it isn't the only resource. Let's obtain {item.rad}",
		},
	},
}

function tutorial(): Quest
	return quest_from_stages("tutorial", tutorial_stages, tutorial_stages_server)
end

return {
	tutorial = tutorial,
}
