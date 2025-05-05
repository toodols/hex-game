local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local updates_mod = require(script.Parent.updates)
local new_signal = require(ReplicatedStorage.Shared.signal).new_signal
local action_phase_mod = require(script.Parent.action_phase)

type World = types.World
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
	if schedule.running then
		return
	end
	schedule.running = true
	if schedule.now ~= nil then
		local diff = os.clock() - schedule.now
		schedule.start_time += diff
		schedule.end_time += diff
		schedule.start_time_sync += diff
	end
	if schedule.wait_thread then
		task.cancel(schedule.wait_thread)
	end
	coroutine.resume(schedule.loop_thread)
end

-- Pauses the turn schedule
function turn_schedule_stop(schedule: TurnSchedule)
	if not schedule.running then
		return
	end
	schedule.running = false
	schedule.now = os.clock()
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

function recalculate_skips(world: World)
	local needed_skips = 0
	for _, team in world.teams do
		needed_skips += #team.players
	end

	if needed_skips == 0 then
		return
	end

	if #world.skipped >= needed_skips and world.turn_schedule ~= nil then
		world.skipped = {}
		updates_mod.add_update(world, {
			type = "turn_skips",
			current_skips = 0,
			needed_skips = needed_skips,
		})
		updates_mod.add_update(world, {
			type = "turn_skipped",
		})
		turn_schedule_skip(world.turn_schedule)
	else
		world.needed_skips = needed_skips
		world.current_skips = #world.skipped
		updates_mod.add_update(world, {
			type = "turn_skips",
			current_skips = #world.skipped,
			needed_skips = needed_skips,
		})
	end
end

-- Reports the turn time to the players
function report_turn_time(world: World)
	assert(world.turn_schedule, "no turn schedule")
	updates_mod.add_update(world, {
		type = "turn_timer",
		schedule = {
			start_time_sync = world.turn_schedule.start_time_sync,
			start_time = world.turn_schedule.start_time,
			end_time = world.turn_schedule.end_time,
			running = world.turn_schedule.running,
		},
	})
	updates_mod.flush_updates(world)
end

-- Resets the turn time to the beginning (does not report)
function reset_turn_time(world: World, schedule: TurnSchedule)
	local count_entities = 0
	-- todo: simply counting every entity is a terrible way to scale game time
	for _ in world:active_entities() do
		count_entities += 1
	end
	local wait_time = count_entities * world.speed_multiplier + world.speed_base
	schedule.now = nil
	schedule.start_time_sync = workspace:GetServerTimeNow()
	schedule.start_time = os.clock()
	schedule.end_time = os.clock() + wait_time
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

function bootstrap(world: World)
	world.turn_schedule = new_turn_schedule(function()
		reset_turn_time(world, world.turn_schedule :: TurnSchedule)
		report_turn_time(world)
	end, function()
		world.skipped = {}
		recalculate_skips(world)
		action_phase_mod.run_action_phase(world)
	end)
	reset_turn_time(world, world.turn_schedule :: TurnSchedule)
	turn_schedule_resume(world.turn_schedule :: TurnSchedule)
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
	bootstrap = bootstrap,
}
