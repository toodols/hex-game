local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local registry_mod = require(script.Parent.registry)
local registry = registry_mod.registry
local server_types = require(ServerScriptService.Server.types)
local with_defaults = registry_mod.with_defaults

type Entity = types.Entity
type HexGrid = types.HexGrid
type ActionState = server_types.ActionState

registry["factory"] = with_defaults {
	autogenerate_wires = true,
	init = function(self: Entity, grid: HexGrid)
		self.current_recipe = "vit_to_tek"
	end,
	tick = function(self: Entity, grid: HexGrid, action_state: ActionState)
		local config = grid.entity_configurations[self.type]
		if self.status == "complete" and self.enabled and self.owner ~= grid.neutral_team then
			local recipe = config.recipes[self.current_recipe]
			if recipe then
				table.insert(grid.action_queue, {
					entity_id = self.id,
					type = "exchange",
					input_power = recipe.input_power,
					input_items = recipe.input_items,
					output_items = recipe.output_items,
				})
			end
		end
	end,
}

return {}
