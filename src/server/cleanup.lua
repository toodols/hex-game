local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local turn_scheduler = require(script.Parent.turn_scheduler)
type World = types.World

function cleanup(world: World)
	if world.turn_schedule then
		turn_scheduler.turn_schedule_kill(world.turn_schedule)
	end
end

return {
	cleanup = cleanup,
}
