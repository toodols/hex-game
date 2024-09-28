local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local updates_mod = require(script.Parent.updates)
local new_signal = require(ReplicatedStorage.Shared.signal).new_signal

type HexGrid = types.HexGrid
type TurnSchedule = types.TurnSchedule

-- still don't like how tightly coupled TurnSchedule is with HexGrid
-- especially with it depending on the signal listener to reset the end time

function turn_schedule_skip(schedule: TurnSchedule, end_time: number?)
	schedule.turn_end_time = end_time or 0
	if schedule.wait_thread then
		task.cancel(schedule.wait_thread)
	end
	coroutine.resume(schedule.loop_thread)
end

function recalculate_skips(grid: HexGrid)
	assert(grid.turn_schedule, "turn_schedule is nil")
	local needed_skips = 0
	for _, team in grid.teams do
		needed_skips += #team.players
	end

	if needed_skips == 0 then
		return
	end

	if #grid.skipped >= needed_skips then
		turn_schedule_skip(grid.turn_schedule)
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

function reset_turn_time(grid: HexGrid)
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
	updates_mod.flush_updates(grid)
	if grid.turn_schedule then
		grid.turn_schedule.turn_end_time = grid.turn_end_time
	end
end

function new_turn_schedule(turn_end_time: number): TurnSchedule
	local schedule

	local wait_thread: thread
	local loop_thread: thread
	loop_thread = coroutine.create(function()
		while true do
			while DateTime.now().UnixTimestampMillis < schedule.turn_end_time do
				wait_thread = task.delay(
					(schedule.turn_end_time - DateTime.now().UnixTimestampMillis) / 1000,
					function()
						coroutine.resume(loop_thread)
					end
				)
				coroutine.yield()
			end
			-- just a precaution so it doesn't go into an infinite loop
			schedule.turn_end_time = math.huge
			schedule.turn_signal.send()
		end
	end)

	schedule = {
		turn_signal = new_signal(),
		wait_thread = wait_thread,
		loop_thread = loop_thread,
		turn_end_time = turn_end_time,
	}

	coroutine.resume(loop_thread)
	return schedule
end

return {
	new_turn_schedule = new_turn_schedule,
	reset_turn_time = reset_turn_time,
	turn_schedule_skip = turn_schedule_skip,
	recalculate_skips = recalculate_skips,
}
