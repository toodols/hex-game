local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local shared_entity_mod = require(ReplicatedStorage.Shared.entity)
local is_allied = require(ReplicatedStorage.Shared.team).is_allied

local world_mod = require(ReplicatedStorage.Shared.world)
local effect_mod = require(script.Parent.effect)
local entity_mod = require(script.Parent.entity)

type Damage = types.Damage
type DamageResult = types.DamageResult
type Entity = types.Entity
type World = types.World
type HexCell = types.HexCell
type CubicCoordinate = types.CubicCoordinate
type EntityId = types.EntityId

-- damage is applied independently for each cell
-- for each cell, damage is a gauge gradually reduced for each entity
-- entities that occupy multiple cells are treated as multiple entities
-- only the highest damage to each entity is applied
-- damage with a gauge of 0 hitting an entity with a max health of 0 will kill the entity and also propagate

-- Ex:
-- 1     2
--       D(5)
-- A(   10  )
-- B(5)  C(5)
--
-- Damage of 15 on cell 1 and 2:
-- Gauge 1 = 15
-- A(10 -> 0)
-- Gauge 1 = 5
-- B(5 -> 0)
-- Gauge 1 = 0
--
-- Gauge 2 = 15
-- D(5 -> 0)
-- Gauge 2 = 10
-- A(10 -> 0)
-- Gauge 2 = 0
-- C(5 -> 5)
--
-- End result:
-- 1     2
--       D(0)
-- A(0)  A(0)
-- B(0)  C(5)

function apply_entity_damage(entity: Entity, amount: number, piercing: boolean): number
	local total = 0
	if amount == 0 then
		return total
	end

	if not piercing then
		for _, effect in entity.effects do
			if effect.type == "shield" then
				local effective = math.min(amount, effect.health)
				total += effective
				effect.health -= effective
				amount -= effective
				if effect.health <= 0 then
					effect.is_destroyed = true
				end
			end
			if amount == 0 then
				return total
			end
		end
	end

	effect_mod.purge_destroyed_effects(entity)

	local effective = math.min(amount, entity.health)
	total += effective
	entity.health = entity.health - effective
	return total
end

function damage_entity(world: World, entity: Entity, damage: Damage): { [EntityId]: DamageResult }
	damage.nonlethal = damage.nonlethal or false
	damage.friendly_fire = damage.friendly_fire or false
	damage.piercing = damage.piercing or false
	damage.damage_type = damage.damage_type or "physical"

	if damage.damage_type == "healing" then
		local effective = math.min(damage.amount, entity.max_health - entity.health)
		entity.health += effective
		return {
			[entity.id] = {
				amount = effective,
				lethal = false,
			},
		}
	elseif damage.damage_type == "physical" then
		local health = if damage.piercing then entity.health else shared_entity_mod.get_effective_health(entity)
		local gauge = damage.amount
		local effective = math.clamp(if damage.nonlethal then health - 1 else health, 0, gauge)
		gauge -= effective
		health -= effective

		apply_entity_damage(entity, effective, damage.piercing :: boolean)

		return { [entity.id] = {
			amount = effective,
			lethal = health <= 0 and not damage.nonlethal,
		} }
	else
		error("unknown damage type " .. damage.damage_type :: any)
	end
end

function get_attackable_entities(world: World, cell: HexCell, damage: Damage): { Entity }
	local team = if damage.from then world.entities[damage.from].owner else nil
	local entities = {}
	for entity_id in cell.entities do
		local entity = world.entities[entity_id]
		if
			-- ignore destroyed entities
			not entity.is_destroyed
			-- ignore blueprints
			and entity.status ~= "blueprint"
			-- do not attack friendly entities unless friendly_fire is on
			and (damage.friendly_fire or not is_allied(world, entity.owner, team))
			-- ignore entities that will die, but is delayed
			and entity.server_data.will_die == nil
		then
			table.insert(entities, entity)
		end
	end

	table.sort(entities, world_mod.layer_comparator(world))
	return entities
end

function damage_cells(world: World, targets: { CubicCoordinate }, damage: Damage): { [EntityId]: DamageResult }
	damage.nonlethal = damage.nonlethal or false
	damage.friendly_fire = damage.friendly_fire or false
	damage.piercing = damage.piercing or false
	damage.damage_type = damage.damage_type or "physical"

	if damage.damage_type == "healing" then
		error "todo"
	elseif damage.damage_type == "physical" then
		-- different cells may give different damage values to one entity
		-- this keeps track of the highest damage
		local damage_results: { [EntityId]: DamageResult } = {}

		for _, target in targets do
			local cell = world:get_cell(target)
			local gauge = damage.amount

			local entities = get_attackable_entities(world, cell, damage)

			for _, entity in entities do
				local health = if damage.piercing then entity.health else shared_entity_mod.get_effective_health(entity)
				local effective = math.clamp(if damage.nonlethal then health - 1 else health, 0, gauge)
				health -= effective

				damage_results[entity.id] = {
					amount = math.max(
						if damage_results[entity.id] then damage_results[entity.id].amount else 0,
						effective
					),
					lethal = false,
				}

				gauge -= effective
				if health > 0 or (effective == 0 and health == 0) then
					break
				end
			end
		end

		-- then apply the damage
		for entity_id, damage_result in damage_results do
			local entity = world.entities[entity_id]
			apply_entity_damage(entity, damage_result.amount, damage.piercing :: boolean)
			if entity.health <= 0 then
				damage_result.lethal = true
			end

			world:add_update {
				type = "entity_update",
				entity = entity,
			}
			local event = {
				type = "entity_event",
				event_type = "took_damage",
				entity_id = entity_id,
				damage = damage,
				damage_result = damage_result,
			}
			table.insert(world.action_queue, event)
			world:add_update(event)
		end

		return damage_results
	else
		error("unknown damage type " .. damage.damage_type :: any)
	end
end

-- marks entities to be destroyed at the end of the turn
function delayed_destruction(world: World, damage_results: { [EntityId]: DamageResult }, damage: Damage?)
	for entity_id, damage_result in damage_results do
		if damage_result.lethal then
			local entity = world.entities[entity_id]
			local event = {
				type = "entity_event",
				event_type = "destroy",
				entity_id = entity_id,
				death_type = "killed",
				damage = damage,
				damage_result = damage_result,
			}
			world:add_update(event)
			table.insert(world.action_queue, event)
			entity.server_data.will_die = {
				death_type = "killed",
			}
		end
	end
end

-- immediately destroys entities
function destroy_entities(world: World, damage_results: { [EntityId]: DamageResult }, _damage: Damage?)
	for entity_id, result in damage_results do
		if result.lethal then
			entity_mod.remove_entity(world, world.entities[entity_id])
		end
	end
end

function damage_entity_destroying(world: World, entity: Entity, damage: Damage)
	destroy_entities(world, damage_entity(world, entity, damage), damage)
end

return {
	damage_cells = damage_cells,
	damage_entity = damage_entity,
	destroy_entities = destroy_entities,
	damage_entity_destroying = damage_entity_destroying,
	delayed_destruction = delayed_destruction,
}
