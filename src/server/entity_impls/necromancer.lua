local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local entity_mod = require(ServerScriptService.Server.entity)
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)
local coords = require(ReplicatedStorage.Shared.coords)
local damage_mod = require(ServerScriptService.Server.damage)

type Entity = types.Entity
type World = types.World
type EntityEvent = types.EntityEvent
type ActionState = server_types.ActionState
type EntityId = types.EntityId

entity_mod.registry.necromancer = entity_mod.with_defaults {
	autogenerates_vertex = true,
	influences = function(self: Entity, world: World)
		local config = world.entity_configurations[self.type]
		local neighbors = coords.neighbors_leq(self.primary_coordinate, config.range)
		for _, coord in neighbors do
			local cell = world:get_cell(coord)
			if cell then
				cell.influences[self.id] = true
			end
		end
	end,
	on_event = function(self: Entity, world: World, event: EntityEvent, action_state: ActionState)
		if event.event_type == "destroy" and event.death_type == "killed" then
			local entity = world.entities[event.entity_id]
			if entity.owner ~= self.owner then
				return
			end
			if not world.entity_configurations[entity.type].can_revive then
				return
			end
			if #world:query_entity {
				coordinate = entity.primary_coordinate,
				type = "grave",
			} > 0 then
				print "Grave already exists"
				return
			end

			local damage = {
				type = "physical",
				amount = 1,
				from = self.id,
			}
			damage_mod.delayed_destruction(world, damage_mod.damage_entity(world, self, damage), damage)
			world:add_update {
				type = "entity_update",
				entity = self,
			}

			local revived_entity = entity_mod.revive_entity(entity_mod.clone_entity(entity))
			revived_entity.active = false
			revived_entity.max_health = 1
			revived_entity.health = 1
			world.entities[revived_entity.id] = revived_entity

			local grave = entity_mod.new_entity({
				type = "grave",
				primary_coordinate = entity.primary_coordinate,
				status = "scaffold",
				revives_into = revived_entity.id,
				owner = self.owner,
			}, world)

			revived_entity.server_data.subject_of = grave.id
		end
	end,
}

entity_mod.registry.grave = entity_mod.with_defaults {
	on_completed = function(self: Entity, world: World)
		self.health = 0
		local event = {
			type = "entity_event",
			event_type = "destroy",
			entity_id = self.id,
			death_type = "used",
		}
		world:add_update(event)
		self.server_data.will_die = {
			death_type = "used",
		}
		local revived_entity = world.entities[self.revives_into :: EntityId]
		revived_entity.server_data.subject_of = nil
		revived_entity.server_data.subject_type = nil
		entity_mod.activate_entity(world, revived_entity)
		entity_mod.autogenerate_vertex(world, revived_entity)
		print(revived_entity)
	end,
}

return {}
