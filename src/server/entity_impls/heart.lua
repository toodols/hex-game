local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local entity_mod = require(ServerScriptService.Server.entity)
local researches_mod = require(ReplicatedStorage.Shared.researches)

local research_item = researches_mod.research_item

type Entity = types.Entity
type World = types.World
type Heart = Entity & {
	bonus_clock: number,
}

entity_mod.registry.heart = entity_mod.with_defaults {
	autogenerates_vertex = true,
	init = function(self: Heart, world: World)
		self.bonus_clock = 0
		self.researches = {
			queue = {},
			states = {
				create_rad = research_item {
					coord = { 1, 0, -1 },
					id = "create_rad",
				},
				create_bar = research_item {
					coord = { 0, -1, 1 },
					id = "create_bar",
				},
				create_tek = research_item {
					coord = { -1, 1, 0 },
					id = "create_tek",
				},
			},
		}
	end,

	tick = function(self: Heart, world: World)
		if self.bonus_clock == nil then
			self.bonus_clock = 0
			-- error "no bonus_clock"
		end
		if self.status == "complete" then
			assert(self.researches, "no researches")
			local output_items = { "bar" }
			local bonus_item
			if self.researches.states.create_rad.status == "complete" then
				bonus_item = "rad"
			elseif self.researches.states.create_bar.status == "complete" then
				bonus_item = "bar"
			elseif self.researches.states.create_tek.status == "complete" then
				bonus_item = "tek"
			end

			if bonus_item ~= nil and self.bonus_clock % 2 == 0 then
				self.bonus_clock = (self.bonus_clock + 1) % 2
				table.insert(output_items, bonus_item)
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
