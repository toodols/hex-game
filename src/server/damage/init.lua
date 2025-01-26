local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local server_entity_mod = require(script.Parent.entity)
local server_types = require(script.Parent.types)
local updates_mod = require(script.Parent.updates)
local shared_entity_mod = require(ReplicatedStorage.Shared.entity)
local effect_methods = require(script.Parent.effect.methods)

type Damage = types.Damage
type Entity = types.Entity
type HexGrid = types.HexGrid
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

function apply_entity_damage(entity: Entity, amount: number): number
	local total = 0
	if amount == 0 then
		return total
	end
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

	effect_methods.purge_destroyed_effects(entity)

	local effective = math.min(amount, entity.health)
	total += effective
	entity.health = entity.health - effective
	return total
end

function damage_entity(grid: HexGrid, entity: Entity, damage: Damage): { [EntityId]: boolean }
	damage.nonlethal = damage.nonlethal or false
	damage.friendly_fire = damage.friendly_fire or false
	local health = shared_entity_mod.get_effective_health(entity)
	local gauge = damage.amount
	local effective = math.clamp(if damage.nonlethal then health - 1 else health, 0, gauge)
	gauge -= effective
	health -= effective

	apply_entity_damage(entity, effective)
	if health <= 0 and not damage.nonlethal then
		return { [entity.id] = true }
	end
	return {}
end

function damage_cells(grid: HexGrid, targets: { CubicCoordinate }, damage: Damage): { [EntityId]: boolean }
	damage.nonlethal = damage.nonlethal or false
	damage.friendly_fire = damage.friendly_fire or false
	local destroyed_entities = {}
	local team = if damage.from then grid.entities[damage.from].owner else nil

	-- calculate the damage each entity should take
	local damage_values: { [EntityId]: number } = {}
	for _, target in targets do
		local cell = grid:get_cell(target)
		local gauge = damage.amount
		local entities = {}

		for entity_id in cell.entities do
			local entity = grid.entities[entity_id]
			if not entity.is_destroyed and entity.status ~= "blueprint" then
				table.insert(entities, entity)
			end
		end

		table.sort(entities, function(a, b)
			return grid.entity_configurations[a.type].layer > grid.entity_configurations[b.type].layer
		end)

		for _, entity in entities do
			if not damage.friendly_fire and entity.owner == team then
				continue
			end
			local health = shared_entity_mod.get_effective_health(entity)
			local effective = math.clamp(if damage.nonlethal then health - 1 else health, 0, gauge)
			gauge -= effective
			health -= effective
			damage_values[entity.id] = math.max(damage_values[entity.id] or 0, effective)
			if health > 0 or (effective == 0 and health == 0) then
				break
			end
		end
	end

	-- then apply the damage
	for entity_id, value in damage_values do
		local entity = grid.entities[entity_id]
		apply_entity_damage(entity, value)

		updates_mod.add_update(grid, {
			type = "entity_update",
			entity = entity,
		})
		table.insert(grid.action_queue, {
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
		table.insert(grid.action_queue, {
			type = "entity_event",
			event_type = "dealt_damage",
			entity_id = damage.from,
			damage = damage,
		})
	end

	return destroyed_entities
end

function destroy_entities(grid: HexGrid, destroyed_entities: { [EntityId]: boolean })
	for entity_id in destroyed_entities do
		server_entity_mod.remove_entity(grid, grid.entities[entity_id])
	end
end

function damage_entity_destroying(grid: HexGrid, entity: Entity, damage: Damage)
	destroy_entities(grid, damage_entity(grid, entity, damage))
end

return {
	damage_cells = damage_cells,
	damage_entity = damage_entity,
	destroy_entities = destroy_entities,
	damage_entity_destroying = damage_entity_destroying,
}
