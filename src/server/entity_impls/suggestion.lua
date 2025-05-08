local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local entity_mod = require(ServerScriptService.Server.entity)
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)
local effect_mod = require(ServerScriptService.Server.effect)
local team_mod = require(ReplicatedStorage.Shared.team)

type Entity = types.Entity
type World = types.World
type EntityEvent = types.EntityEvent

function try_to_convert(world: World, entity: Entity)
	print "suggestion tick"
	if entity.status ~= "complete" then
		return true
	end

	local cell = world:get_cell(entity.primary_coordinate)
	for entity_id in cell.entities do
		if entity_id == entity.id then
			continue
		end
		local other = world.entities[entity_id]
		if other.status == "blueprint" then
			continue
		end
		if team_mod.is_allied(world, other.owner, entity.owner) then
			continue
		end

		-- two suggestions annihilate each other
		if other.type == "suggestion" then
			-- todo: add update that says suggestions were annihilated
			other.server_data.will_die = other.server_data.will_die or {
				death_type = "killed",
			}
			entity.server_data.will_die = entity.server_data.will_die or {
				death_type = "killed",
			}
		else
			other.owner = entity.owner
			entity.server_data.will_die = entity.server_data.will_die or {
				death_type = "used",
			}
		end
	end

	return true
end

entity_mod.registry.suggestion = entity_mod.with_defaults {
	decayable = false,
	incorporeal = true,
	init = function(self: Entity, world: World)
		effect_mod.add_exclusive_effect(self, {
			type = "hidden",
		})
	end,
	influences = function(self: Entity, world: World)
		local cell = world:get_cell(self.primary_coordinate)
		cell.influences[self.id] = true
	end,
	tick = function(self: Entity, world: World)
		table.insert(world.action_queue, {
			type = "run_late",
			entity_id = self.id,
			run = try_to_convert,
		})
	end,
	on_event = function(self: Entity, world: World, event: EntityEvent)
		if event.entity_id == self.id and event.event_type == "destroy" and event.death_type == "killed" then
			try_to_convert(world, self)
		end
	end,
}

return {}
