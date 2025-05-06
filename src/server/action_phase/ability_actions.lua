local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)

local util = require(ReplicatedStorage.Shared.util)
local shared_entity_mod = require(ReplicatedStorage.Shared.entity)

local systems_mod = require(ServerScriptService.Server.systems)
local damage_mod = require(ServerScriptService.Server.damage)
local updates_mod = require(ServerScriptService.Server.updates)
local server_entity_mod = require(ServerScriptService.Server.entity)
local server_util = require(ServerScriptService.Server.util)
local visibility_mod = require(ServerScriptService.Server.visibility)

type World = types.World
type ActionState = server_types.ActionState
type Entity = types.Entity
type EntityAction = types.EntityAction

function scout_attack(world: World, action_state: ActionState, ability: EntityAction)
	assert(ability.type == "ability", "Expected ability")
	local entity = world.entities[ability.entity_id]
	local config = world.entity_configurations[entity.type]
	local cost = config.abilities[ability.ability_type].cost

	local system = action_state.system_by_entity_id[ability.entity_id]

	if not systems_mod.system_has_items(world, action_state, system, cost) then
		return
	end

	for item_type, amount in cost do
		systems_mod.system_consume_item_type(world, action_state, system, item_type, amount)
	end

	local event = {
		type = "entity_event",
		event_type = "consumed_items",
		entity_id = ability.entity_id,
		items = cost,
	}
	table.insert(world.action_queue, event)
	updates_mod.add_update(world, event)

	local cell = world:get_cell(ability.coordinate)
	assert(cell, "cell not found")

	updates_mod.add_update(world, ability)
	local damage = table.clone(shared_entity_mod.registry[entity.type].abilities[ability.ability_type].damage)
	damage.from = ability.entity_id

	damage_mod.delayed_destruction(world, damage_mod.damage_cells(world, { cell.coordinate }, damage))
end

function disguise_ability(world: World, action_state: ActionState, ability: EntityAction)
	assert(ability.type == "ability", "Expected ability")

	local entity = world.entities[ability.entity_id]
	local coordinate = ability.coordinate
	-- get the entity to copy
	local cell = world:get_cell(coordinate)
	if not cell then
		warn "invalid coordinate"
		return
	end

	-- get the list of entities, filter the ones visible to this team
	-- ignore entities that occupy more than one cell and sort it by layer
	local entities = util.table_filter(
		world:query_entity {
			coordinate = coordinate,
			status = "complete",
		},
		function(target_entity)
			return visibility_mod.entity_visibility(world, target_entity, entity.owner)
				and #target_entity.coordinates == 1
		end
	)

	table.sort(entities, function(a, b)
		return world.entity_configurations[a.type].layer > world.entity_configurations[b.type].layer
	end)

	local top = entities[1]
	if not top then
		return
	end

	-- treat entity disguising as itself as resetting disguise
	if top == entity then
		if entity.disguise then
			world.entities[entity.disguise].is_destroyed = true
			updates_mod.add_update(world, {
				type = "entity_update",
				entity = world.entities[entity.disguise],
			})
		end
		entity.disguise = nil
		updates_mod.add_update(world, {
			type = "disguise",
			entity_id = entity.id,
		})
		return
	end

	if top.disguise ~= nil then
		-- disguise a disguise???
		top = world.entities[top.disguise]
	end

	local copied = util.deep_copy(top)
	copied.disguise = nil
	copied.active = false
	copied.id = server_util.new_global_id()
	copied.primary_coordinate = entity.primary_coordinate
	copied.coordinates = entity.coordinates
	copied.owner = entity.owner
	copied.is_destroyed = false
	copied.server_data.is_disguise_of = entity.id
	world.entities[copied.id] = copied
	entity.disguise = copied.id
	updates_mod.add_update(world, {
		type = "entity_update",
		entity = copied,
	})
	updates_mod.add_update(world, {
		type = "entity_disguise",
		entity_id = entity.id,
		disguise_id = copied.id,
	})
end

function handle_ability_actions(world: World, action_state: ActionState)
	for _, ability in
		util.table_extract(world.action_queue, function(value)
			return (value.type == "ability")
		end)
	do
		if ability.ability_type == "scout_attack" or ability.ability_type == "turret_attack" then
			scout_attack(world, action_state, ability)
		elseif ability.ability_type == "solution_use" then
			local entity = world.entities[ability.entity_id]
			server_entity_mod.registry[entity.type].abilities[ability.ability_type](entity, world)
			local event = {
				type = "entity_event",
				event_type = "destroy",
				entity_id = entity.id,
				death_type = "used",
			}
			updates_mod.add_update(world, event)
			entity.server_data.will_die = { death_type = "used" }
		elseif ability.ability_type == "disguise" then
			disguise_ability(world, action_state, ability)
		end
	end
end

return {
	handle_ability_actions = handle_ability_actions,
}
