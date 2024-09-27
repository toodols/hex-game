local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local updates_mod = require(script.Parent.updates)
local action_phase_mod = require(script.Parent.action_phase)

type HexGrid = types.HexGrid
type TurnSchedule = types.TurnSchedule

function turn_schedule(grid: HexGrid): TurnSchedule
	local co: thread
	local wait_thread: thread
	local function skip()
		if wait_thread then
			task.cancel(wait_thread)
		end
		coroutine.resume(co)
	end

	local schedule = {
		skip = skip,
		recalculate_skips = function()
			local needed_skips = 0
			for _, team in grid.teams do
				needed_skips += #team.players
			end

			if needed_skips == 0 then
				return
			end

			if #grid.skipped >= needed_skips then
				skip()
			else
				grid.needed_skips = needed_skips
				grid.current_skips = #grid.skipped
				table.insert(grid.updates_buffer[#grid.updates_buffer], {
					type = "turn_skips",
					current_skips = #grid.skipped,
					needed_skips = needed_skips,
				})
			end
		end,
	}

	co = coroutine.create(function()
		while true do
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
			schedule.recalculate_skips()
			updates_mod.flush_updates(grid)
			wait_thread = task.delay(wait_time, function()
				coroutine.resume(co)
			end)
			coroutine.yield(wait_time)
			local success, err = pcall(function()
				action_phase_mod.run_action_phase(grid)
			end)
			if not success then
				warn(err)
			end
		end
	end)

	coroutine.resume(co)
	return schedule
end

return {
	turn_schedule = turn_schedule,
}
