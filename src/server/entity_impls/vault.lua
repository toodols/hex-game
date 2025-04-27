local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local entity_mod = require(ServerScriptService.Server.entity)

type Entity = types.Entity
type World = types.World

entity_mod.registry.vault = entity_mod.with_defaults {
	autogenerates_vertex = true,
	init = function(self: Entity, world: World)
		local config = world.entity_configurations[self.type]
		if not self.inventory then
			self.inventory = {
				filter = {
					type = "blacklist",
					items = {},
				},
				homogeneous = true,
				capacity = 0,
				items = {},
			}
		end
	end,
	on_completed = function(self: Entity, world: World)
		local config = world.entity_configurations[self.type]
		if self.inventory then
			self.inventory.capacity = config.inventory_capacity
		end
	end,
}

return {}
