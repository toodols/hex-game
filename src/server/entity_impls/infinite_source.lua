local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)

local entity_mod = require(ServerScriptService.Server.entity)
local server_types = require(ServerScriptService.Server.types)

type Entity = types.Entity & {
	mode: "passive" | "active",
}
type World = types.World
type ActionState = server_types.ActionState

entity_mod.registry.infinite_source = entity_mod.with_defaults {
	autogenerates_vertex = true,
	init = function(self: Entity, world: World)
		self.mode = "passive"
	end,
	tick = function(self: Entity, world: World, action_state: ActionState)
		if self.mode == "active" then
			table.insert(world.action_queue, {
				entity_id = self.id,
				type = "exchange",
				output_power = 999,
				output_items = util.table_flat(util.table_map({ "bar", "rad", "vit" }, function(item)
					return util.table_map(util.range(10), function()
						return item
					end)
				end)),
			})
		end
	end,
}

return {}
