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

registry.heart = with_defaults {
	autogenerate_wires = true,
	init = function(self: Entity, grid: HexGrid)
		-- self.should_output = 0
	end,
	tick = function(self: Entity, grid: HexGrid, action_state: ActionState)
		local config = grid.entity_configurations[self.type]
		if self.status == "complete" then
			table.insert(grid.action_queue, {
				entity_id = self.id,
				type = "exchange",
				-- output_items = if self.should_output == 0 then { "bar" } else {},
				output_items = { "bar" },
				output_power = config.output_power,
			})
			-- self.should_output = (self.should_output + 1) % 2
		end
	end,
}

return {}
