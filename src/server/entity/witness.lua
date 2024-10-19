local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)
local registry_mod = require(script.Parent.registry)
local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults

type Entity = types.Entity
type HexGrid = types.HexGrid
type EntityEvent = types.EntityEvent
type ActionState = server_types.ActionState

registry["witness"] = with_defaults {
	autogenerate_wires = true,
	on_completed = function(self: Entity, grid: HexGrid) end,
	on_event = function(self: Entity, grid: HexGrid, event: EntityEvent, action_state: ActionState)
		if event.event_type == "dealt_damage" then

		end
	end,
}

return {}
