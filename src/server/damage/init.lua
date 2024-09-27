local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local server_entity_mod = require(script.Parent.entity)
local server_util = require(script.Parent.util)
local server_types = require(script.Parent.types)

type Damage = types.Damage
type Entity = types.Entity
type HexGrid = types.HexGrid
type CubicCoordinate = types.CubicCoordinate
type EntityId = types.EntityId
type ActionState = server_types.ActionState

-- damage is applied independently for each cell
-- for each cell, damage is a gauge gradually reduced for each entity
-- entities that occupy multiple cells are treated as multiple entities
-- only the highest damage is applied

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

function damage_entity(entity: Entity, damage: number)
	for effect_type, effect in entity.effects do
		if damage == 0 then
			return
		end
		if effect_type == "shield" then
			local effective = math.min(damage, effect.health)
			effect.health -= effective
			damage -= effective
			if effect.health <= 0 then
				entity.effects[effect_type] = nil
			end
		end
	end

	if damage > 0 then
		entity.health = math.max(entity.health - damage, 0)
	end
end

function apply_damage_on_cells(grid: HexGrid, targets: { CubicCoordinate }, damage: Damage, action_state: ActionState?)
	damage.lethal = damage.lethal or true
	damage.friendly_fire = damage.friendly_fire or false
	local team = if damage.from then grid.entities[damage.from].owner else nil
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
			local behavior = server_entity_mod.registry[entity.type]
			local result = behavior.take_damage(entity, grid, damage, gauge)
			gauge -= result.effective
			damage_values[entity.id] = math.max(damage_values[entity.id] or 0, result.effective)
			if not result.propagate then
				break
			end
		end
	end
	for entity_id, value in damage_values do
		local entity = grid.entities[entity_id]
		damage_entity(entity, value)

		if action_state then
			server_util.mark_dirty_for_everyone(action_state, entity_id)

			table.insert(grid.updates_buffer[#grid.updates_buffer], {
				type = "entity_damage",
				effective_damage = {
					source = damage,
					amount = value,
					entity_id = entity_id,
					lethal = entity.health <= 0,
				},
			})
		end

		if entity.health <= 0 then
			if action_state then
				action_state.dead_entities[entity_id] = true
			else
				entity.is_destroyed = true
			end
		end
	end
end

return {
	apply_damage_on_cells = apply_damage_on_cells,
}
