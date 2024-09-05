local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local updates_mod = require(script.Parent.updates)
local action_phase_mod = require(script.Parent.action_phase)

type HexGrid = types.HexGrid

function init(grid: HexGrid)
	local co
	co = coroutine.create(function()
		local iter = 0
		while true do
			iter += 1
			local count_entities = 0
			for _ in grid.entities do
				count_entities += 1
			end
			local wait_time = count_entities * grid.speed_multiplier + grid.speed_base
			if grid.turn == 1 then
				wait_time *= 2
			end
			grid.turn_start_time = DateTime.now().UnixTimestampMillis
			grid.turn_end_time = DateTime.now().UnixTimestampMillis + wait_time * 1000
			table.insert(grid.updates_buffer[#grid.updates_buffer], {
				type = "turn_timer",
				turn_start_time = grid.turn_start_time,
				turn_end_time = grid.turn_end_time,
			})
			grid.skipped = {}
			recalculate_skips(grid)
			updates_mod.flush_updates(grid)

			task.delay(wait_time, function(target_iter)
				if iter == target_iter then
					coroutine.resume(co)
				end
			end, iter)
			coroutine.yield(wait_time)
			action_phase_mod.run_action_phase(grid)
		end
	end)

	coroutine.resume(co)

	grid.turn_schedule = {
		skip = function()
			coroutine.resume(co)
		end,
	}
	recalculate_skips(grid)
end

function recalculate_skips(grid: HexGrid)
	local needed_skips = 0
	for _, team in grid.teams do
		needed_skips += #team.players
	end

	if #grid.skipped >= needed_skips then
		grid.turn_schedule.skip()
	else
		grid.needed_skips = needed_skips
		grid.current_skips = #grid.skipped
		table.insert(grid.updates_buffer[#grid.updates_buffer], {
			type = "turn_skips",
			current_skips = #grid.skipped,
			needed_skips = needed_skips,
		})
	end
end

return {
	init = init,
	recalculate_skips = recalculate_skips,
}
