local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local entity_mod = require(ServerScriptService.Server.entity)
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)

type Entity = types.Entity
type World = types.World
type ActionState = server_types.ActionState

entity_mod.registry.factory = entity_mod.with_defaults {
	autogenerates_vertex = true,
	init = function(self: Entity, world: World)
		self.current_recipe = "vit_to_tek"
	end,
	tick = function(self: Entity, world: World, action_state: ActionState)
		local config = world.entity_configurations[self.type]
		if self.status == "complete" and self.enabled and self.owner ~= world.neutral_team then
			local recipe = config.recipes[self.current_recipe]
			if recipe then
				table.insert(world.action_queue, {
					entity_id = self.id,
					type = "exchange",
					input_items = recipe.input_items,
					output_items = recipe.output_items,
				})
			end
		end
	end,
}

return {}
