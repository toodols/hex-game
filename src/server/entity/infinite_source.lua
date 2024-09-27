local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local registry_mod = require(script.Parent.registry)
local registry = registry_mod.registry
local server_types = require(ServerScriptService.Server.types)
local with_defaults = registry_mod.with_defaults
local util = require(ReplicatedStorage.Shared.util)

type Entity = types.Entity & {
	mode: "passive" | "active",
}
type HexGrid = types.HexGrid
type ActionState = server_types.ActionState

registry["infinite_source"] = with_defaults {
	autogenerate_wires = true,
	init = function(self: Entity, grid: HexGrid)
		self.mode = "passive"
	end,
	tick = function(self: Entity, grid: HexGrid, action_state: ActionState)
		if self.mode == "active" then
			table.insert(action_state.queue, {
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
