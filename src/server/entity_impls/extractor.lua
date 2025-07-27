local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)
local entity_mod = require(ServerScriptService.Server.entity)
local get_deposit_type = require(ReplicatedStorage.Shared.deposit).get_deposit_type
local set_deposit_type = require(ServerScriptService.Server.deposit).set_deposit_type

type ActionState = server_types.ActionState
type Entity = types.Entity
type World = types.World
type EntityEvent = types.EntityEvent
type DepositType = types.DepositType

entity_mod.registry.extractor = entity_mod.with_defaults {
	autogenerates_vertex = true,
	init = function(self: Entity, world: World)
		self.should_output = 0
		self.deposit = get_deposit_type(world, self.primary_coordinate)
	end,
	tick = function(self: Entity, world: World, action_state: ActionState)
		local config = world.entity_configurations[self.type]
		if self.status == "complete" and self.enabled and self.owner ~= world.neutral_team then
			local deposit_type = get_deposit_type(world, self.primary_coordinate)

			local system = action_state.system_by_entity_id[self.id]
			local is_boosted = system.heart == "anima"
			local function ok()
				self.should_output = ((self.should_output :: any) + 1)
					% (if is_boosted then 1 else config.cycles_to_output)
			end
			if is_boosted or self.should_output == 0 then
				local items
				if deposit_type == "bar_deposit" then
					items = { "bar" }
				elseif deposit_type == "vit_deposit" then
					items = { "vit" }
				elseif deposit_type == "rad_deposit" then
					items = { "rad" }
				elseif deposit_type == "tar_deposit" then
					items = { "tar" }
				else
					warn "No deposit under extractor. This might be a bug"
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
			world:add_update {
				type = "entity_update",
				entity = self,
			}
		end
	end,
	on_event = function(self: Entity, world: World, event: EntityEvent)
		if event.entity_id == self.id and event.event_type == "destroy" and event.death_type == "killed" then
			local cell = world:get_cell(self.primary_coordinate)
			assert(cell, "cell not found")
			set_deposit_type(world, cell.coordinate, self.deposit)
		end
	end,
}

return {}
