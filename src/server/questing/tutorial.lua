local ServerScriptService = game:GetService "ServerScriptService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local action_phase_mod = require(ServerScriptService.Server.action_phase)
local quest_from_stages = require(script.Parent.quest).quest_from_stages
local tutorial_stages = require(ReplicatedStorage.Shared.questing).tutorial_stages

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

function tutorial()
	return quest_from_stages("tutorial", tutorial_stages, tutorial_stages_server)
end

return {
	tutorial = tutorial,
}
