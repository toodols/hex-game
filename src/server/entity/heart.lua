local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local registry_mod = require(script.Parent.registry)
local registry = registry_mod.registry
local server_types = require(ServerScriptService.Server.types)
local with_defaults = registry_mod.with_defaults
local shared_entity_mod = require(ReplicatedStorage.Shared.entity)
local shared_behavior = shared_entity_mod.registry["heart"]

type Entity = types.Entity
type HexGrid = types.HexGrid
type ActionState = server_types.ActionState

registry["heart"] = with_defaults {
	autogenerate_wires = true,
	init = function(self: Entity, grid: HexGrid)
		-- self.should_output = 0
	end,
	tick = function(self: Entity, grid: HexGrid, action_state: ActionState)
		if self.status == "complete" then
			table.insert(action_state.queue, {
				entity_id = self.id,
				type = "exchange",
				-- output_items = if self.should_output == 0 then { "bar" } else {},
				output_items = { "bar" },
				output_power = shared_behavior.output_power,
			})
			-- self.should_output = (self.should_output + 1) % 2
		end
	end,
}

return {}
