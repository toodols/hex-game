local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local entity_mod = require(ServerScriptService.Server.entity)
local server_types = require(ServerScriptService.Server.types)
local researches_mod = require(ReplicatedStorage.Shared.researches)

type Entity = types.Entity
type World = types.World
type ActionState = server_types.ActionState
type Heart = Entity & {
	rad_clock: number,
}
entity_mod.registry.heart = entity_mod.with_defaults {
	autogenerates_vertex = true,
	init = function(self: Heart, world: World)
		self.rad_clock = 0
		self.researches = {
			queue = {},
			states = researches_mod.create_heart_researches(),
		}
	end,
	tick = function(self: Heart, world: World, action_state: ActionState)
		if self.status == "complete" then
			assert(self.researches, "no researches")
			local output_items = { "bar" }
			if self.researches.states.create_rad.status == "complete" and self.rad_clock % 2 == 0 then
				self.rad_clock = (self.rad_clock + 1) % 2
				table.insert(output_items, "rad")
			end
			table.insert(world.action_queue, {
				entity_id = self.id,
				type = "exchange",
				output_items = output_items,
			})
		end
	end,
}

return {}
