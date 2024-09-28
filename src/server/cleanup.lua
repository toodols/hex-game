local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local turn_scheduler = require(script.Parent.turn_scheduler)
type HexGrid = types.HexGrid

function cleanup(grid: HexGrid)
	if grid.turn_schedule then
		turn_scheduler.kill_turn_schedule(grid.turn_schedule)
	end
end

return {
	cleanup = cleanup,
}
