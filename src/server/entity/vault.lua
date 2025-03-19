local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local registry_mod = require(script.Parent.registry)
local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults

type Entity = types.Entity
type World = types.World

registry.vault = with_defaults {
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
