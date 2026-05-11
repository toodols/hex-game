local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local coords = require(ReplicatedStorage.Shared.coords)
local util = require(ReplicatedStorage.Shared.util)
local team_mod = require(ReplicatedStorage.Shared.team)
local effect_mod = require(script.Parent.effect)
local systems_mod = require(script.Parent.systems)
local damage_mod = require(script.Parent.damage)
local visibility_mod = require(script.Parent.visibility)
local server_entity_mod = require(script.Parent.entity)
local world_mod = require(ReplicatedStorage.Shared.world)

type World = types.World
type Entity = types.Entity
type Ability = types.Ability
type Interaction = types.Interaction

local abilities: {
	[string]: (world: World, entity: Entity, ability: Ability, interaction: Interaction?) -> (),
} = {}

abilities.cannon = function(world: World, entity: Entity, ability: Ability, interaction: Interaction?)
	assert(ability.type == "cannon", "Ability type should be cannon")
	assert(interaction and interaction.type == "ability", "Interaction type should be ability")

	local cost = ability.cost

	local system = world.systems[world.entity_system_map[entity.id]]

	if not systems_mod.system_has_items(world, system, cost) then
		return
	end

	for item_type, amount in cost do
		systems_mod.system_consume_item_type(world, system, item_type, amount)
	end

	local event = {
		type = "entity_event",
		event_type = "consumed_items",
		entity_id = entity.id,
		items = cost,
	}
	table.insert(world.action_queue, event)
	world:add_update(event)

	local cell = world:get_cell(interaction.coordinate)
	assert(cell, "cell not found")

	world:add_update(interaction)
	local damage = table.clone(ability.damage)
	damage.from = entity.id

	damage_mod.delayed_destruction(world, damage_mod.damage_cells(world, { cell.coordinate }, damage), damage)
end

abilities.disguise = function(world: World, entity: Entity, ability: Ability, interaction: Interaction?)
	assert(ability.type == "disguise", "Expected ability to be disguise")
	assert(interaction and interaction.type == "ability", "Expected interaction to be ability")

	local coordinate = interaction.coordinate
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
			return visibility_mod.entity_visibility(world, { team = entity.owner }, target_entity)
				and #target_entity.coordinates == 1
		end
	)

	table.sort(entities, world_mod.layer_comparator(world))

	local top = entities[1]
	if not top then
		return
	end

	-- treat entity disguising as itself as resetting disguise
	if top == entity then
		-- if entity.disguise then
		-- 	world.entities[entity.disguise].is_destroyed = true
		-- 	world:add_update {
		-- 		type = "entity_update",
		-- 		entity = world.entities[entity.disguise],
		-- 	}
		-- end
		entity.disguise = nil
		world:add_update {
			type = "disguise",
			entity_id = entity.id,
		}
		return
	end

	if top.disguise ~= nil then
		-- disguise a disguise???
		top = world.entities[top.disguise]
	end

	local copied = server_entity_mod.clone_entity(top)
	copied.server_data.child_relationship = "disguise"
	copied.server_data.parent = entity.id
	copied.active = false
	copied.disguise = nil
	copied.is_destroyed = false
	world.entities[copied.id] = copied
	entity.disguise = copied.id
	world:add_update {
		type = "entity_update",
		entity = copied,
	}
	world:add_update {
		type = "entity_disguise",
		entity_id = entity.id,
		disguise_id = copied.id,
	}
end

abilities.impression_activate = function(world: World, entity: Entity, ability: Ability)
	for _, cell in
		util.table_filter_map(coords.neighbors_leq(entity.primary_coordinate, 1), function(coord)
			return world:get_cell(coord)
		end)
	do
		for entity_id in cell.entities do
			local affected_entity = world.entities[entity_id]
			if team_mod.is_allied(world, entity.owner, affected_entity.owner) then
				continue
			end
			effect_mod.add_exclusive_effect(world, affected_entity, {
				type = "infected",
				duration = 1,
			})
		end
	end

	local event = {
		type = "entity_event",
		event_type = "destroy",
		entity_id = entity.id,
		death_type = "used",
	}
	world:add_update(event)
	entity.server_data.will_die = { death_type = "used" }
end

abilities.solution_activate = function(world: World, entity: Entity, ability: Ability, interaction: Interaction?)
	local config = world.entity_configurations[entity.type]
	for _, cell in
		util.table_filter_map(coords.neighbors_many_leq(entity.coordinates, 1), function(coord)
			return world:get_cell(coord)
		end)
	do
		for entity_id in cell.entities do
			local affected_entity = world.entities[entity_id]

			-- it would be nice to use damage_mod for this but it doesn't support healing damage
			-- and this ignores layers
			affected_entity.health =
				math.min(affected_entity.max_health, affected_entity.health + config.abilities.activate.heal_amount)

			effect_mod.add_effect(world, affected_entity, {
				type = "shield",
				health = config.abilities.activate.shield_health,
				duration = config.abilities.activate.shield_duration,
			})

			world:add_update {
				type = "entity_update",
				entity = affected_entity,
			}
		end
	end

	local event = {
		type = "entity_event",
		event_type = "destroy",
		entity_id = entity.id,
		death_type = "used",
	}
	world:add_update(event)
	entity.server_data.will_die = { death_type = "used" }
end

abilities.rash = function(world: World, entity: Entity, ability: Ability, interaction: Interaction?)
	assert(ability.type == "rash", "Expected ability to be rash")
	assert(interaction and interaction.type == "ability", "Expected interaction to be ability")

	local coordinate = interaction.coordinate
end

return {
	abilities = abilities,
}
