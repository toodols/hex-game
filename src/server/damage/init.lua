local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local shared_entity_mod = require(ReplicatedStorage.Shared.entity)
local is_allied = require(ReplicatedStorage.Shared.team).is_allied

local server_types = require(script.Parent.types)
local updates_mod = require(script.Parent.updates)
local effect_mod = require(script.Parent.effect)
local entity_mod = require(script.Parent.entity)

type Damage = types.Damage
type DamageResult = types.DamageResult
type Entity = types.Entity
type World = types.World
type HexCell = types.HexCell
type CubicCoordinate = types.CubicCoordinate
type EntityId = types.EntityId
type ActionState = server_types.ActionState

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

function damage_entity(world: World, entity: Entity, damage: Damage): DamageResult
	damage.nonlethal = damage.nonlethal or false
	damage.friendly_fire = damage.friendly_fire or false
	damage.piercing = damage.piercing or false
	if damage.type == "healing" then
		local effective = math.min(damage.amount, entity.max_health - entity.health)
		entity.health += effective
		return {
			[entity.id] = {
				amount = effective,
				lethal = false,
			},
		}
	end

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
		then
			table.insert(entities, entity)
		end
	end

	table.sort(entities, function(a, b)
		return world.entity_configurations[a.type].layer > world.entity_configurations[b.type].layer
	end)
	return entities
end

function damage_cells(world: World, targets: { CubicCoordinate }, damage: Damage): DamageResult
	damage.nonlethal = damage.nonlethal or false
	damage.friendly_fire = damage.friendly_fire or false
	damage.piercing = damage.piercing or false

	if damage.type == "healing" then
		error "todo"
	end

	local destroyed_entities = {}

	-- different cells may give different damage values to one entity
	-- this keeps track of the highest damage
	local damage_values: { [EntityId]: number } = {}

	for _, target in targets do
		local cell = world:get_cell(target)
		local gauge = damage.amount

		local entities = get_attackable_entities(world, cell, damage)

		-- -- compile all the altars that have influence on this cell
		-- local altars = {}
		-- for entity_id in cell.influences do
		-- 	local entity = world.entities[entity_id]
		-- 	if
		-- 		entity.type == "altar"
		-- 		-- altar on the cell being attacked does not count
		-- 		and not coords.coords_eq(entity.primary_coordinate, target)
		-- 	then
		-- 		table.insert(altars, entity)
		-- 	end
		-- end

		-- -- oldest entities take precedence
		-- table.sort(altars, function(a, b)
		-- 	return a.server_data.requested_at < b.server_data.requested_at
		-- end)

		-- local done = false
		-- for _, entity in entities do
		-- 	for _, altar in altars do
		-- 		if is_allied(world, entity.owner, altar.owner) then
		-- 			local new_attackables =
		-- 				get_attackable_entities(world, world:get_cell(altar.primary_coordinate) :: HexCell, damage)

		-- 			-- if the altar is at the top, logically there is nothing to sacrifice
		-- 			-- do not retarget.
		-- 			if new_attackables[1] == altar then
		-- 				continue
		-- 			end

		-- 			-- all the entities ABOVE but excluding the altar may be targeted
		-- 			entities = {}
		-- 			for other_entity in new_attackables do
		-- 				if other_entity == altar then
		-- 					break
		-- 				end
		-- 				table.insert(entities, other_entity)
		-- 			end
		-- 			done = true
		-- 			break
		-- 		end
		-- 		if done then
		-- 			break
		-- 		end
		-- 	end
		-- end

		for _, entity in entities do
			local health = if damage.piercing then entity.health else shared_entity_mod.get_effective_health(entity)
			local effective = math.clamp(if damage.nonlethal then health - 1 else health, 0, gauge)
			health -= effective
			damage_values[entity.id] = math.max(damage_values[entity.id] or 0, effective)

			gauge -= effective
			if health > 0 or (effective == 0 and health == 0) then
				break
			end
		end
	end

	-- then apply the damage
	for entity_id, value in damage_values do
		local entity = world.entities[entity_id]
		apply_entity_damage(entity, value, damage.piercing :: boolean)

		updates_mod.add_update(world, {
			type = "entity_update",
			entity = entity,
		})
		table.insert(world.action_queue, {
			type = "entity_event",
			event_type = "took_damage",
			entity_id = entity_id,
			effective_damage = {
				source = damage,
				amount = value,
				entity_id = entity_id,
				lethal = entity.health <= 0,
			},
		})

		if entity.health <= 0 then
			destroyed_entities[entity_id] = true
		end
	end

	if damage.from ~= nil then
		table.insert(world.action_queue, {
			type = "entity_event",
			event_type = "dealt_damage",
			entity_id = damage.from,
			damage = damage,
		})
	end

	return destroyed_entities
end

function destroy_entities(world: World, results: DamageResult)
	for entity_id, result in results do
		if result.lethal then
			entity_mod.remove_entity(world, world.entities[entity_id])
		end
	end
end

function damage_entity_destroying(world: World, entity: Entity, damage: Damage)
	destroy_entities(world, damage_entity(world, entity, damage))
end

return {
	damage_cells = damage_cells,
	damage_entity = damage_entity,
	destroy_entities = destroy_entities,
	damage_entity_destroying = damage_entity_destroying,
}
