local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)

type World = types.World
type System = types.System

local HEART_BY_PRIORITY = {
	infinite_source = 3,
	heart = 2,
	anima = 1,
}

function get_heart(world: World, system: System): string
	local heart = nil
	for entity_id in system.entities do
		local entity = world.entities[entity_id]
		if
			HEART_BY_PRIORITY[entity.type] ~= nil
			and (heart == nil or HEART_BY_PRIORITY[entity.type] > HEART_BY_PRIORITY[heart])
		then
			heart = entity.type
		end
	end
	return heart
end

return {
	get_heart = get_heart,
}
