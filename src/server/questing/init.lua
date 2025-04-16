local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local new_signal = require(ReplicatedStorage.Shared.signal).new_signal

type World = types.World
type CubicCoordinate = types.CubicCoordinate

type QuestStage = types.QuestStage
type Quest = types.Quest
type ServerQuestStageBehavior = types.ServerQuestStageBehavior

local function quest_change_state(quest: Quest, stage: string, world: World)
	if not stage then
		print "end state"
		return
	end
	if not quest.stages_data[stage] or quest.current_stage == stage then
		return
	end
	quest.current_stage = stage
	local behavior = quest.stages_behavior[stage]
	if behavior and behavior.stage_start then
		behavior.stage_start(quest, world)
	end
	quest.quest_update_signal.send(quest)
end

local function quest_advance(quest: Quest, world: World)
	local stage_data = quest.stages_data[quest.current_stage]
	quest_change_state(quest, stage_data.next, world)
end

local function quest_update(quest: Quest, world: World)
	local stage_data = quest.stages_data[quest.current_stage]
	local stage_behavior = quest.stages_behavior[quest.current_stage]
	if
		stage_behavior
		and stage_behavior.progression_requisite
		and stage_behavior.progression_requisite(quest, world)
	then
		quest_change_state(quest, stage_data.next, world)
	end
end

local function quest_select_choice(quest: Quest, world: World, choice: string)
	local stage_behavior = quest.stages_behavior[quest.current_stage]
	if stage_behavior and stage_behavior.choice_selected then
		stage_behavior.choice_selected(quest, world, choice)
		quest.quest_update_signal.send(quest)
	end
end

local function quest_serialize(quest: Quest, world: World)
	return {
		id = quest.id,
		current_stage = quest.current_stage,
		current_stage_data = quest.stages_data[quest.current_stage],
		details = quest.details,
		title = quest.title,
	}
end

function new_quest(props: {
	id: string,
	title: string,
	stages_data: { [string]: QuestStage },
	stages_behavior: { [string]: ServerQuestStageBehavior },
	details: any,
}): Quest
	local quest = {
		title = props.title,
		current_stage = "init",
		details = props.details or {},
		stages_data = props.stages_data,
		current_stage_data = nil :: any,
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
	quest_select_choice = quest_select_choice,
	quest_serialize = quest_serialize,
}