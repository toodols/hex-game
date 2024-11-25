local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local updates_mod = require(script.Parent.updates)
local new_signal = require(ReplicatedStorage.Shared.signal).new_signal

type HexGrid = types.HexGrid
type TurnSchedule = types.TurnSchedule

-- don't like how much of a mess this all is

-- Skips the turn schedule so that it goes to the next turn immediately
function turn_schedule_skip(schedule: TurnSchedule)
	schedule.end_time = 0
	if schedule.wait_thread then
		task.cancel(schedule.wait_thread)
	end
	coroutine.resume(schedule.loop_thread)
end

-- Resumes the turn schedule
function turn_schedule_resume(schedule: TurnSchedule)
	schedule.running = true
	if schedule.wait_thread then
		task.cancel(schedule.wait_thread)
	end
	coroutine.resume(schedule.loop_thread)
end

-- Pauses the turn schedule
function turn_schedule_stop(schedule: TurnSchedule)
	schedule.running = false
	if schedule.wait_thread then
		task.cancel(schedule.wait_thread)
	end
end

function turn_schedule_kill(schedule: TurnSchedule)
	if schedule.wait_thread then
		task.cancel(schedule.wait_thread)
	end
	coroutine.close(schedule.loop_thread)
end

function recalculate_skips(grid: HexGrid)
	local needed_skips = 0
	for _, team in grid.teams do
		needed_skips += #team.players
	end

	if needed_skips == 0 then
		return
	end

	if #grid.skipped >= needed_skips and grid.turn_schedule ~= nil then
		grid.skipped = {}
		turn_schedule_skip(grid.turn_schedule)
	else
		grid.needed_skips = needed_skips
		grid.current_skips = #grid.skipped
		updates_mod.add_update(grid, {
			type = "turn_skips",
			current_skips = #grid.skipped,
			needed_skips = needed_skips,
		})
	end
end

-- Reports the turn time to the players
function report_turn_time(grid: HexGrid)
	assert(grid.turn_schedule, "no turn schedule")
	updates_mod.add_update(grid, {
		type = "turn_timer",
		schedule = {
			start_time_sync = grid.turn_schedule.start_time_sync,
			start_time = grid.turn_schedule.start_time,
			end_time = grid.turn_schedule.end_time,
			running = grid.turn_schedule.running,
		},
	})
	updates_mod.flush_updates(grid)
end

-- Resets the turn time to the beginning (does not report)
function reset_turn_time(grid: HexGrid, turn_schedule: TurnSchedule)
	local count_entities = 0
	for _ in grid.entities do
		count_entities += 1
	end
	local wait_time = count_entities * grid.speed_multiplier + grid.speed_base
	turn_schedule.start_time_sync = workspace:GetServerTimeNow()
	turn_schedule.start_time = os.clock()
	turn_schedule.end_time = os.clock() + wait_time
end

function new_turn_schedule(get_end_time: () -> number, run_turn: () -> ()): TurnSchedule
	local schedule = {
		wait_thread = nil,
		loop_thread = nil,
		running = false,
		start_time = 0,
		end_time = 0,
		get_end_time = get_end_time,
		run_turn = run_turn,
		turn_ran_signal = new_signal(),
	} :: TurnSchedule

	schedule.loop_thread = coroutine.create(function()
		while true do
			while os.clock() < schedule.end_time or not schedule.running do
				if schedule.running then
					-- if the end time is not a reasonable value, the game will stop
					if schedule.end_time - os.clock() < 1000000 then
						schedule.wait_thread = task.delay((schedule.end_time - os.clock()), function()
							schedule.wait_thread = nil
							coroutine.resume(schedule.loop_thread)
						end)
					else
						error "An irrecoverable error occurred and the game will stop now"
					end
				end
				coroutine.yield()
			end

			schedule.end_time = math.huge
			task.spawn(function()
				schedule.run_turn()
				schedule.turn_ran_signal.send()
				if schedule.running then
					schedule.get_end_time()
				end
			end)
		end
	end)

	return schedule
end

return {
	new_turn_schedule = new_turn_schedule,
	turn_schedule_resume = turn_schedule_resume,
	reset_turn_time = reset_turn_time,
	turn_schedule_skip = turn_schedule_skip,
	recalculate_skips = recalculate_skips,
	turn_schedule_stop = turn_schedule_stop,
	turn_schedule_kill = turn_schedule_kill,
	report_turn_time = report_turn_time,
}
