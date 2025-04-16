local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local entity_mod = require(ServerScriptService.Server.entity)
local registry = entity_mod.registry
local with_defaults = entity_mod.with_defaults

type Entity = types.Entity
type World = types.World

registry.stockpile = with_defaults {
	autogenerates_vertex = true,
	on_completed = function(self: Entity, world: World)
		local config = world.entity_configurations[self.type]
		if not self.inventory then
			self.inventory = {
				filter = {
					type = "blacklist",
					items = {},
				},
				homogeneous = false,
				capacity = config.inventory_capacity,
				items = {},
			}
		end
	end,
}

return {}
