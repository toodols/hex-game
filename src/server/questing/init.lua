local tutorial = require(script.tutorial).tutorial
local quest = require(script.quest)

return {
	tutorial = tutorial,
	quest_advance = quest.quest_advance,
	quest_update = quest.quest_update,
}
