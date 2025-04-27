local ServerScriptService = game:GetService "ServerScriptService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local server_types = require(ServerScriptService.Server.types)
local items_mod = require(ReplicatedStorage.Shared.items)
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)

local handle_exchange_actions = require(script.Parent.exchange_actions).handle_exchange_actions
local handle_ability_actions = require(script.Parent.ability_actions).handle_ability_actions
local handle_try_promote_actions = require(script.Parent.try_promote_actions).handle_try_promote_actions
local handle_advance_research_actions = require(script.Parent.advance_research_actions).handle_advance_research_actions
local handle_entity_event_actions = require(script.Parent.entity_event_actions).handle_entity_event_actions

type World = types.World
type ActionState = server_types.ActionState

--- Processes all actions in world.action_queue. requires systems to be created
function process_queue(world: World, action_state: ActionState)
	local old_queue
	local iterations = 0
	local MAX_ALLOWED_ITERATIONS = 100
	local function should_terminate(): boolean
		if iterations > MAX_ALLOWED_ITERATIONS then
			warn "MAX_ALLOWED_ITERATIONS reached"
			warn("left in queue", world.action_queue)
			return true
		end
		iterations += 1
		if #old_queue ~= #world.action_queue then
			return false
		end
		for i, action in old_queue do
			if action ~= world.action_queue[i] then
				return false
			end
		end
		return true
	end

	-- prevent silly mistakes like table.insert(action_queue, {{ type = "ability" }}) by ensuring that
	-- all actions have a type
	-- i would love to do an exhaustive check against every possible action type, but this takes effort
	for _, action in world.action_queue do
		if action.type == nil then
			print(action)
			error "^ not an action"
		end
	end

	repeat
		old_queue = {}
		for _, action in world.action_queue do
			table.insert(old_queue, action)
		end

		handle_exchange_actions(world, action_state)
		handle_ability_actions(world, action_state)
		handle_try_promote_actions(world, action_state)
		handle_advance_research_actions(world, action_state)
		handle_entity_event_actions(world, action_state)

		for _, system in action_state.systems do
			-- add overflow items to inventory
			for _, open_inventory_entity in
				util.table_filter_map(util.table_keys(system.entities), function(entity_id)
					local inventory = world.entities[entity_id].inventory
					if inventory and inventory.capacity > #inventory.items then
						return world.entities[entity_id]
					end
					return nil
				end)
			do
				if #system.overflow_items == 0 then
					break
				end
				items_mod.inventory_deposit(open_inventory_entity.inventory, system.overflow_items)
			end
		end
	until should_terminate()

	-- clear action queue
	world.action_queue = {}
end

return {
	process_queue = process_queue,
}
