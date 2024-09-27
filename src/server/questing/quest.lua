local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local new_signal = require(ReplicatedStorage.Shared.signal).new_signal

type HexGrid = types.HexGrid
type CubicCoordinate = types.CubicCoordinate

type QuestStage = types.QuestStage
type Quest = types.Quest
type QuestMessage = types.QuestMessage
type ServerQuestStageBehavior = types.ServerQuestStageBehavior

function quest_from_stages(
	quest_id: string,
	stages_data: { [string]: QuestStage },
	server_stages_behavior: { [string]: ServerQuestStageBehavior }
): (Quest, QuestMessage)
	local quest

	local function to_message(): QuestMessage
		return {
			quest_id = quest_id,
			title = quest_id,
			messages = stages_data[quest.stage].messages,
			effects = stages_data[quest.stage].effects or {},
			can_advance = stages_data[quest.stage].can_advance or false,
		}
	end
	local function change_stage(stage: string)
		if stage == "end" then
		end
		if not stages_data[stage] or quest.stage == stage then
			return
		end
		quest.stage = stage
		quest.message_change_signal.send(to_message())
	end

	quest = {
		stage = "init",
		message_change_signal = new_signal(),
		advance = function()
			local stage_data = stages_data[quest.stage]
			if stage_data.can_advance then
				if stage_data.next then
					change_stage(stage_data.next)
				else
					change_stage "end"
				end
			end
		end,
		update = function(grid: HexGrid)
			local stage_data = stages_data[quest.stage]
			local stage_behavior = server_stages_behavior[quest.stage]
			if stage_behavior.progression_requisite then
				stage_behavior.progression_requisite(quest, grid)
			end
		end,
	}

	return quest, to_message()
end

return {
	quest_from_stages = quest_from_stages,
}
