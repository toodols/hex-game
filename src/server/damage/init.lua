local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local server_entity_mod = require(script.Parent.entity)
local shared_entity_mod = require(ReplicatedStorage.Shared.entity)
local remotes_mod = require(script.Parent.remotes)
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

function apply_damage(grid: HexGrid, target: CubicCoordinate, damage: Damage, action_state: ActionState?)
	
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

		for _, entity_id in cell.entities do
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
		entity.health -= value
		if action_state then
			action_state.dirty_entities[entity_id] = action_state.dirty_entities[entity_id] or {}
			action_state.dirty_entities[entity_id].everyone = true

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
