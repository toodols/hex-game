local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)
local entity_mod = require(ServerScriptService.Server.entity)
local updates_mod = require(ServerScriptService.Server.updates)

type ActionState = server_types.ActionState
type Entity = types.Entity
type World = types.World
type EntityEvent = types.EntityEvent
type HexCell = types.HexCell

entity_mod.registry.extractor = entity_mod.with_defaults {
	autogenerates_vertex = true,
	built_on = { "bar_deposit", "vit_deposit", "rad_deposit", "tar_deposit" },
	init = function(self: Entity, world: World)
		self.should_output = 0
		self.deposit = (world:get_cell(self.primary_coordinate) :: HexCell).type
	end,
	tick = function(self: Entity, world: World, action_state: ActionState)
		local config = world.entity_configurations[self.type]
		if self.status == "complete" and self.enabled and self.owner ~= world.neutral_team then
			local cell = world:get_cell(self.primary_coordinate)

			local is_boosted = false
			local function ok()
				self.should_output = ((self.should_output :: any) + 1)
					% (if is_boosted then 1 else config.cycles_to_output)
			end
			if self.should_output == 0 then
				local items
				if cell.type == "bar_deposit" then
					items = { "bar" }
				elseif cell.type == "vit_deposit" then
					items = { "vit" }
				elseif cell.type == "rad_deposit" then
					items = { "rad" }
				elseif cell.type == "tar_deposit" then
					items = { "tar" }
				elseif cell.type == "basic" then
					warn "Extractor is placed on a basic cell. This might be a bug"
				end
				if items then
					table.insert(world.action_queue, {
						type = "exchange",
						output_items = items,
						entity_id = self.id,
						on_success = function()
							ok()
						end,
					})
				end
			else
				ok()
			end
			updates_mod.add_update(world, {
				type = "entity_update",
				entity = self,
			})
		end
	end,
	on_event = function(self: Entity, world: World, event: EntityEvent)
		if event.entity_id == self.id and event.event_type == "destroy" and event.death_type == "killed" then
			local cell = world:get_cell(self.primary_coordinate)
			assert(cell, "cell not found")
			cell.type = self.deposit
		end
	end,
}

return {}
