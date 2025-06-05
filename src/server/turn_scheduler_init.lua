local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local new_signal = require(ReplicatedStorage.Shared.signal).new_signal
local turn_scheduler = require(script.Parent.turn_scheduler)
local action_phase_mod = require(script.Parent.action_phase)

type World = types.World
type TurnSchedule = types.TurnSchedule

function new_turn_schedule(world: World): TurnSchedule
	local schedule = {
		wait_thread = nil,
		loop_thread = nil,
		running = false,
		start_time = 0,
		end_time = 0,
	} :: TurnSchedule

	hydrate(world, schedule)

	return schedule
end

function hydrate(world: World, schedule: TurnSchedule)
	schedule.turn_ran_signal = new_signal()
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
	schedule.get_end_time = function()
		turn_scheduler.reset_turn_time(world, schedule :: TurnSchedule)
		turn_scheduler.report_turn_time(world)
	end

	schedule.run_turn = function()
		world.skipped = {}
		turn_scheduler.recalculate_skips(world)
		action_phase_mod.run_action_phase(world)
	end
end

function bootstrap(world: World)
	world.turn_schedule = new_turn_schedule(world)
	turn_scheduler.reset_turn_time(world, world.turn_schedule :: TurnSchedule)
	turn_scheduler.turn_schedule_resume(world.turn_schedule :: TurnSchedule)
end

return {
	new_turn_schedule = new_turn_schedule,
	hydrate = hydrate,
	bootstrap = bootstrap,
}