local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)
local entity_mod = require(ServerScriptService.Server.entity)
local updates_mod = require(ServerScriptService.Server.updates)
local world_mod = require(ReplicatedStorage.Shared.world)
local items_mod = require(ReplicatedStorage.Shared.items)
local coords = require(ReplicatedStorage.Shared.coords)

type ActionState = server_types.ActionState
type Entity = types.Entity
type World = types.World
type EntityEvent = types.EntityEvent
type HexCell = types.HexCell

entity_mod.registry.fountain = entity_mod.with_defaults {
	autogenerates_vertex = true,
	built_on = { "bar_deposit", "vit_deposit", "rad_deposit", "tar_deposit" },
	init = function(self: Entity, world: World) end,
	on_completed = function(self: Entity, world: World)
		if self.status ~= "complete" then
			return
		end
		local cell = world:get_cell(self.primary_coordinate)
		local event = {
			type = "entity_event",
			event_type = "destroy",
			entity_id = self.id,
			death_type = "used",
		}
		world:add_update(event)
		self.server_data.will_die = { death_type = "used" }
		local deposit_ty = cell.type
		local item_ty
		if deposit_ty == "bar_deposit" then
			item_ty = "bar"
		elseif deposit_ty == "vit_deposit" then
			item_ty = "vit"
		elseif deposit_ty == "rad_deposit" then
			item_ty = "rad"
		elseif deposit_ty == "tar_deposit" then
			item_ty = "tar"
		end

		cell.type = "basic"

		for _, neighbor_cell in world_mod.into_cells(world, coords.neighbors_leq(self.primary_coordinate, 2)) do
			for entity_id in neighbor_cell.entities do
				local entity = world.entities[entity_id]
				if entity.owner ~= self.owner then
					continue
				end
				-- if entity.type == "blueprint" and entity.cost[item_ty] ~= nil and entity.cost[item_ty] > 0 then
				-- 	local diff = entity.cost[item_ty] - entity.cost_fulfilled[item_ty]
				-- 	entity.cost_fulfilled[item_ty] += diff
				-- 	local consumed = {}
				-- 	for i = 1, diff do
				-- 		table.insert(consumed, item_ty)
				-- 	end
				-- 	local consumed_event = {
				-- 		type = "entity_event",
				-- 		event_type = "consumed_items",
				-- 		entity_id = entity.id,
				-- 		items = consumed,
				-- 	}
				-- 	table.insert(world.action_queue, consumed_event)
				-- 	world:add_update(consumed_event)
				-- 	world:add_update {
				-- 		type = "entity_update",
				-- 		entity = entity,
				-- 	}
				-- end
				if entity.inventory ~= nil and items_mod.item_can_deposit(item_ty, entity.inventory) then
					for i = #entity.inventory.items + 1, entity.inventory.capacity do
						table.insert(entity.inventory.items, item_ty)
					end
					world:add_update {
						type = "entity_update",
						entity = entity,
					}
				end
			end
		end
	end,
}

return {}
