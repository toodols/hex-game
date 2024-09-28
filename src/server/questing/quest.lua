local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local new_signal = require(ReplicatedStorage.Shared.signal).new_signal

type HexGrid = types.HexGrid
type CubicCoordinate = types.CubicCoordinate

type QuestStage = types.QuestStage
type Quest = types.Quest
type ServerQuestStageBehavior = types.ServerQuestStageBehavior

local function quest_change_state(quest: Quest, stage: string)
	if not stage then
		print "end state"
		return
	end
	if not quest.stages_data[stage] or quest.current_stage == stage then
		return
	end
	quest.current_stage = stage
	quest.quest_update_signal.send(quest)
end

local function quest_advance(quest: Quest)
	local stage_data = quest.stages_data[quest.current_stage]
	if stage_data.can_advance then
		quest_change_state(quest, stage_data.next)
	end
end

local function quest_update(quest: Quest, grid: HexGrid)
	local stage_data = quest.stages_data[quest.current_stage]
	local stage_behavior = quest.stages_behavior[quest.current_stage]
	print(stage_behavior)
	if stage_behavior.progression_requisite and stage_behavior.progression_requisite(quest, grid) then
		quest_change_state(quest, stage_data.next)
	end
end

function new_quest(props: {
	id: string,
	stages_data: { [string]: QuestStage },
	stages_behavior: { [string]: ServerQuestStageBehavior },
}): Quest
	local quest = {
		current_stage = "init",
		stages_data = props.stages_data,
		stages_behavior = props.stages_behavior,
		id = props.id,
		quest_update_signal = new_signal(),
	}
	return quest
end

return {
	new_quest = new_quest,
	quest_advance = quest_advance,
	quest_update = quest_update,
	quest_change_state = quest_change_state,
}
